import * as core from "@actions/core";
import { decodeHTML } from "entities";
import { parseArgs, stripVTControlCharacters } from "node:util";
import * as v from "valibot";

const CONFIGURATION_KINDS = ["nixos", "darwin"] as const;
const FAILURE_KINDS = [
  "success",
  "timeout",
  "hydra",
  "transient",
  "deterministic",
  "unknown",
] as const;

const NIX_STORE_DIRECTORY = "/nix/store/";
const NIX_STORE_HASH_LENGTH = 32;
const NIX_STORE_NAME_MAX_LENGTH = 211;
const NIX32_HASH_SOURCE = "[0123456789abcdfghijklmnpqrsvwxyz]{32}";
const NIX_STORE_NAME_CHARACTER_SOURCE = String.raw`[0-9A-Za-z+\-._?=]`;
const DERIVATION_PATH_SOURCE =
  `/nix/store/${NIX32_HASH_SOURCE}-` +
  String.raw`${NIX_STORE_NAME_CHARACTER_SOURCE}+\.drv`;
const DERIVATION_PATH_PATTERN = new RegExp(`^${DERIVATION_PATH_SOURCE}$`, "u");
const DERIVATION_PATH_IN_TEXT_PATTERN = new RegExp(
  String.raw`(?<drvPath>${DERIVATION_PATH_SOURCE})(?=$|[\s,)'"])`,
  "gu",
);
const BUILDING_DERIVATION_PATTERN = new RegExp(
  `building '(?<drvPath>${DERIVATION_PATH_SOURCE})'`,
  "gu",
);

function hasValidDerivationStoreName(drvPath: string): boolean {
  const storeNameStart = NIX_STORE_DIRECTORY.length + NIX_STORE_HASH_LENGTH + 1;
  const storeName = drvPath.slice(storeNameStart);
  const derivationName = storeName.slice(0, -".drv".length);

  return (
    storeName.length <= NIX_STORE_NAME_MAX_LENGTH &&
    derivationName !== "." &&
    derivationName !== ".." &&
    !derivationName.startsWith(".-") &&
    !derivationName.startsWith("..-")
  );
}

const NonNegativeIntegerSchema = v.pipe(
  v.string(),
  v.nonEmpty(),
  v.toNumber(),
  v.safeInteger(),
  v.minValue(0),
);
const OptionalEpochSchema = v.pipe(
  v.optional(v.union([v.literal(""), NonNegativeIntegerSchema])),
  v.transform((value) => (value === "" ? undefined : value)),
);
const EnvironmentSchema = v.object({
  BUILD_CORES: NonNegativeIntegerSchema,
  BUILD_MAX_JOBS: NonNegativeIntegerSchema,
  BUILD_STARTED_AT_EPOCH: OptionalEpochSchema,
  BUILD_TIMEOUT_SECONDS: NonNegativeIntegerSchema,
  CONFIGURATION_KIND: v.picklist(CONFIGURATION_KINDS),
  CONFIGURATION_NAME: v.pipe(v.string(), v.nonEmpty()),
  CONFIGURATION_SYSTEM: v.pipe(v.string(), v.nonEmpty()),
  HYDRA_USER_AGENT: v.pipe(v.string(), v.nonEmpty()),
});
const HydraBuildSchema = v.object({
  buildstatus: v.optional(v.nullable(v.pipe(v.number(), v.safeInteger()))),
  drvpath: v.optional(v.nullable(v.string())),
  finished: v.union([v.boolean(), v.picklist([0, 1])]),
});
const HydraBuildIdSchema = v.pipe(v.string(), v.regex(/^[1-9][0-9]*$/));
const DerivationPathSchema = v.pipe(
  v.string(),
  v.regex(DERIVATION_PATH_PATTERN),
  v.check(hasValidDerivationStoreName),
);

type ConfigurationKind = (typeof CONFIGURATION_KINDS)[number];
type FailureKind = (typeof FAILURE_KINDS)[number];
type RuntimeConfiguration = v.InferOutput<typeof EnvironmentSchema>;

type CommandResult = Readonly<{
  exitCode: number;
  output: string;
  stderr: string;
  stdout: string;
}>;

type Fetcher = (
  input: Request | string | URL,
  init?: RequestInit,
) => Promise<Response>;

type HydraCandidate = Readonly<{
  buildId: string;
  drvPaths: readonly string[];
}>;

type HydraFailure = Readonly<{
  buildId: string;
  drvPath: string;
  status: number;
  url: string;
}>;

type HydraIndexRow = {
  buildId: string;
  name: string;
  status: string;
  system: string;
};

type BuildExecution = Readonly<{
  exitCode: number;
  output: string;
  timedOut: boolean;
}>;

type BuildResult = Readonly<{
  exitCode: number;
  failedDrv: string;
  failureKind: FailureKind;
  failureSummary: string;
  hydraUrl: string;
  retryable: boolean;
  timedOut: boolean;
  timeoutDrv: string;
}>;

type FailureContext = Readonly<{
  failedDrv: string;
  hydraFailure: HydraFailure | null;
  output: string;
  system: string;
  transientFailure: TransientFailure | undefined;
}>;

type FailureRule = Readonly<{
  kind: Exclude<FailureKind, "success" | "timeout">;
  matches: (context: FailureContext) => boolean;
  retryable: boolean;
  summary: (context: FailureContext) => string;
}>;

type TransientFailure = (typeof TRANSIENT_FAILURES)[number];

const runtime: RuntimeConfiguration = v.parse(EnvironmentSchema, process.env);
const HYDRA_FAILURE_INDEX = new URL("https://zh.fail/failed/all.html");
const HYDRA_BUILD_BASE_URL = new URL("https://hydra.nixos.org/build/");
const HYDRA_BUILD_URL_PATTERN = new URLPattern(
  "https://hydra.nixos.org/build/:buildId",
);
const MAX_CAPTURE_LENGTH = 8 * 1024 * 1024;
const MAX_HYDRA_CANDIDATES = 8;
const REQUIRED_STARTUP_DELAY_MILLISECONDS = 45_000;
const DEVELOPMENT_BYPASS_OPTION = "development-bypass-hydra-delay";
const VERIFIED_HYDRA_FAILURES = new Set([1, 6, 10, 11, 12]);

const CONFIGURATION_TARGETS = {
  darwin: (name: string) => `.#darwinConfigurations.${name}.system`,
  nixos: (name: string) => `.#nixosBuilds.${name}`,
} satisfies Record<ConfigurationKind, (name: string) => string>;

const DIRECT_FAILURE_PATTERNS = [
  new RegExp(
    `error: builder for '(?<drvPath>${DERIVATION_PATH_SOURCE})' failed`,
    "u",
  ),
  new RegExp(
    `error: Cannot build '(?<drvPath>${DERIVATION_PATH_SOURCE})'`,
    "u",
  ),
] as const;

const TRANSIENT_FAILURES = [
  {
    description: "DNS lookup failure",
    pattern:
      /EAI_AGAIN|Temporary failure in name resolution|Could not resolve host/i,
  },
  {
    description: "connection failure",
    // Match errno tokens without treating test filenames as network errors
    pattern:
      /(?<![\w./-])(?:ETIMEDOUT|ECONNRESET)(?![\w./-])|Connection (?:timed out|reset|refused)|Failed sending data to the peer/i,
  },
  {
    description: "truncated network response",
    pattern: /unexpected (?:end of file|EOF)/i,
  },
  {
    description: "retryable HTTP response",
    pattern: /HTTP error (?:408|425|429|5[0-9]{2})/i,
  },
  {
    description: "TLS connection failure",
    pattern: /TLS connection was non-properly terminated/i,
  },
  {
    description: "runner storage exhaustion",
    pattern: /No space left on device/i,
  },
  {
    description: "forced runner termination",
    pattern: /killed by signal 9|exit code 137/i,
  },
] as const;

const HYDRA_TEXT_COLUMNS = [
  ["tr > td:nth-child(2)", "name"],
  ["tr > td:nth-child(3)", "system"],
  ["tr > td:nth-child(5)", "status"],
] as const satisfies ReadonlyArray<
  readonly [string, "name" | "status" | "system"]
>;

const RESULT_OUTPUTS = [
  ["exit-code", "exitCode"],
  ["timed-out", "timedOut"],
  ["timeout-drv", "timeoutDrv"],
  ["failed-drv", "failedDrv"],
  ["failure-kind", "failureKind"],
  ["failure-summary", "failureSummary"],
  ["hydra-url", "hydraUrl"],
  ["retryable", "retryable"],
] as const satisfies ReadonlyArray<readonly [string, keyof BuildResult]>;

const FAILURE_RULES = [
  {
    kind: "hydra",
    matches: ({ hydraFailure }) => hydraFailure !== null,
    retryable: false,
    summary: ({ hydraFailure }) =>
      `Nixpkgs Hydra failed this exact derivation (status ${hydraFailure?.status ?? "unknown"}).`,
  },
  {
    kind: "transient",
    matches: ({ failedDrv, output, system }) =>
      isKnownDarwinTwistedTcpTimeout(output, failedDrv, system),
    retryable: true,
    summary: () =>
      "Twisted's known flaky Darwin TCP buffer test timed out (twisted/twisted#12151).",
  },
  {
    kind: "transient",
    matches: ({ transientFailure }) => transientFailure !== undefined,
    retryable: true,
    summary: ({ transientFailure }) =>
      `The build log contains a retryable ${transientFailure?.description ?? "infrastructure failure"}.`,
  },
  {
    kind: "deterministic",
    matches: ({ failedDrv }) => failedDrv.length > 0,
    retryable: false,
    summary: () =>
      "The derivation failed without a retryable infrastructure signature.",
  },
  {
    kind: "unknown",
    matches: () => true,
    retryable: false,
    summary: () =>
      "The build failed without identifying a direct derivation or retryable failure.",
  },
] as const satisfies readonly FailureRule[];

function createResult(overrides: Partial<BuildResult> = {}): BuildResult {
  return {
    exitCode: 0,
    failedDrv: "",
    failureKind: "success",
    failureSummary: "Build completed successfully.",
    hydraUrl: "",
    retryable: false,
    timedOut: false,
    timeoutDrv: "",
    ...overrides,
  };
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function developmentBypassRequested(): boolean {
  const { values } = parseArgs({
    allowPositionals: false,
    args: Bun.argv.slice(2),
    options: {
      [DEVELOPMENT_BYPASS_OPTION]: {
        default: false,
        type: "boolean",
      },
    },
    strict: true,
  });
  return values[DEVELOPMENT_BYPASS_OPTION];
}

type StartupDelayOptions = Readonly<{
  bypassForDevelopment: boolean;
  isGitHubActions: boolean;
  sleep?: (milliseconds: number) => Promise<void>;
}>;

export async function enforceStartupDelay({
  bypassForDevelopment,
  isGitHubActions,
  sleep = Bun.sleep,
}: StartupDelayOptions): Promise<void> {
  if (bypassForDevelopment) {
    if (isGitHubActions) {
      throw new Error(
        `--${DEVELOPMENT_BYPASS_OPTION} is forbidden in GitHub Actions.`,
      );
    }
    console.warn("Skipping the Hydra safety delay for local development.");
    return;
  }

  core.info(
    `Waiting ${REQUIRED_STARTUP_DELAY_MILLISECONDS / 1000} seconds before build orchestration to avoid rapid Hydra consultations.`,
  );
  await sleep(REQUIRED_STARTUP_DELAY_MILLISECONDS);
}

function appendCapture(current: string, addition: string): string {
  return `${current}${addition}`.slice(-MAX_CAPTURE_LENGTH);
}

async function mirrorAndCapture(
  stream: ReadableStream<Uint8Array>,
  destination: NodeJS.WriteStream,
): Promise<string> {
  const decoder = new TextDecoder();
  let captured = "";

  for await (const chunk of stream) {
    destination.write(chunk);
    captured = appendCapture(captured, decoder.decode(chunk, { stream: true }));
  }

  return appendCapture(captured, decoder.decode());
}

function capturedCommand(command: string[]) {
  const processHandle = Bun.spawn(command, {
    env: process.env,
    stderr: "pipe",
    stdout: "pipe",
  });
  const result = Promise.all([
    processHandle.exited,
    mirrorAndCapture(processHandle.stdout, process.stdout),
    mirrorAndCapture(processHandle.stderr, process.stderr),
  ]).then(([exitCode, stdout, stderr]): CommandResult => ({
    exitCode,
    output: appendCapture(stdout, `\n${stderr}`),
    stderr,
    stdout,
  }));
  return { processHandle, result };
}

async function runCommand(command: string[]): Promise<CommandResult> {
  return capturedCommand(command).result;
}

function writeResult(result: BuildResult): void {
  for (const [outputName, property] of RESULT_OUTPUTS) {
    core.setOutput(outputName, result[property]);
  }
}

async function writeSummary(result: BuildResult): Promise<void> {
  const details = [
    `Result: \`${result.failureKind}\``,
    `Retryable: \`${result.retryable}\``,
    ...(result.failedDrv ? [`Failed derivation: \`${result.failedDrv}\``] : []),
    ...(result.hydraUrl ? [`Exact Hydra match: ${result.hydraUrl}`] : []),
    `Summary: ${result.failureSummary}`,
  ];

  await core.summary
    .addHeading("Configuration build result", 3)
    .addList(details)
    .write();
}

export function derivationName(drvPath: string): string | null {
  const result = v.safeParse(DerivationPathSchema, drvPath);
  if (!result.success) {
    return null;
  }

  const nameStart = NIX_STORE_DIRECTORY.length + NIX_STORE_HASH_LENGTH + 1;
  return result.output.slice(nameStart, -".drv".length);
}

function validDerivationPaths(paths: Iterable<string | undefined>): string[] {
  return Array.from(paths).flatMap((path) => {
    const result = v.safeParse(DerivationPathSchema, path);
    return result.success ? [result.output] : [];
  });
}

export function plannedDerivations(output: string): string[] {
  return [
    ...new Set(
      validDerivationPaths(
        Array.from(
          output.matchAll(DERIVATION_PATH_IN_TEXT_PATTERN),
          (match) => match.groups?.drvPath,
        ),
      ),
    ),
  ];
}

function parseHydraBuildId(href: string | null): string {
  const match = href ? HYDRA_BUILD_URL_PATTERN.exec(href) : null;
  const result = v.safeParse(
    HydraBuildIdSchema,
    match?.pathname.groups.buildId,
  );
  return result.success ? result.output : "";
}

export function parseHydraIndex(index: string): HydraIndexRow[] {
  const rows: HydraIndexRow[] = [];
  let activeRow: HydraIndexRow | undefined;

  const rewriter = new HTMLRewriter()
    .on("tr", {
      element(element) {
        const row: HydraIndexRow = {
          buildId: "",
          name: "",
          status: "",
          system: "",
        };
        activeRow = row;
        element.onEndTag(() => {
          if (row.buildId) {
            rows.push({
              ...row,
              name: decodeHTML(row.name).trim(),
              status: decodeHTML(row.status).trim(),
              system: decodeHTML(row.system).trim(),
            });
          }
          if (activeRow === row) {
            activeRow = undefined;
          }
        });
      },
    })
    .on('tr > td:first-child a[href^="https://hydra.nixos.org/build/"]', {
      element(element) {
        if (activeRow) {
          activeRow.buildId = parseHydraBuildId(element.getAttribute("href"));
        }
      },
    });

  for (const [selector, property] of HYDRA_TEXT_COLUMNS) {
    rewriter.on(selector, {
      text(text) {
        if (activeRow) {
          activeRow[property] += text.text;
        }
      },
    });
  }

  rewriter.transform(index);
  return rows;
}

export function hydraCandidates(
  index: string,
  drvPaths: string[],
  system: string,
): HydraCandidate[] {
  const namedPaths = drvPaths.flatMap((drvPath) => {
    const name = derivationName(drvPath);
    return name ? [{ drvPath, name }] : [];
  });
  const pathsByName = Map.groupBy(namedPaths, ({ name }) => name);
  const candidatesByBuildId = Map.groupBy(
    parseHydraIndex(index)
      .filter((row) => row.system === system && row.status === "Failed")
      .flatMap((row) => {
        const matchingPaths = pathsByName.get(row.name) ?? [];
        return matchingPaths.length > 0
          ? [
              {
                buildId: row.buildId,
                drvPaths: matchingPaths.map(({ drvPath }) => drvPath),
              },
            ]
          : [];
      }),
    ({ buildId }) => buildId,
  );

  return [...candidatesByBuildId]
    .map(([buildId, candidates]) => ({
      buildId,
      drvPaths: [...new Set(candidates.flatMap(({ drvPaths }) => drvPaths))],
    }))
    .toSorted((left, right) => {
      const leftId = BigInt(left.buildId);
      const rightId = BigInt(right.buildId);
      return leftId === rightId ? 0 : leftId > rightId ? -1 : 1;
    })
    .slice(0, MAX_HYDRA_CANDIDATES);
}

export class HydraClient {
  readonly #fetcher: Fetcher;
  readonly #system: string;
  readonly #userAgent: string;
  #index: Promise<string | null> | undefined;

  constructor(
    system: string,
    userAgent: string,
    fetcher: Fetcher = (input, init) => globalThis.fetch(input, init),
  ) {
    this.#fetcher = fetcher;
    this.#system = system;
    this.#userAgent = userAgent;
  }

  async #fetchIndex(): Promise<string | null> {
    this.#index ??= (async () => {
      try {
        const response = await this.#fetcher(HYDRA_FAILURE_INDEX, {
          headers: { "User-Agent": this.#userAgent },
          signal: AbortSignal.timeout(30_000),
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }

        return await response.text();
      } catch (error) {
        core.notice(
          `The Zero Hydra Failures index is unavailable (${errorMessage(error)}); continuing.`,
        );
        return null;
      }
    })();

    return this.#index;
  }

  async exactFailure(drvPaths: string[]): Promise<HydraFailure | null> {
    const index = await this.#fetchIndex();
    if (!index) {
      return null;
    }

    const candidates = hydraCandidates(index, drvPaths, this.#system);
    for (const candidate of candidates) {
      try {
        const url = new URL(candidate.buildId, HYDRA_BUILD_BASE_URL);
        const response = await this.#fetcher(url, {
          headers: {
            Accept: "application/json",
            "User-Agent": this.#userAgent,
          },
          signal: AbortSignal.timeout(20_000),
        });

        if (response.status === 404) {
          continue;
        }
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        if (
          !response.headers.get("content-type")?.includes("application/json")
        ) {
          core.notice(
            "Hydra did not return JSON; continuing without the advisory preflight.",
          );
          return null;
        }

        const parsedBuild = v.safeParse(
          HydraBuildSchema,
          await response.json(),
        );
        if (!parsedBuild.success) {
          core.notice(
            `Hydra build ${candidate.buildId} returned an unexpected JSON shape; ignoring it.`,
          );
          continue;
        }

        const build = parsedBuild.output;
        const status = build.buildstatus;
        const drvPath = build.drvpath;
        const finished = build.finished === true || build.finished === 1;
        if (
          finished &&
          typeof drvPath === "string" &&
          candidate.drvPaths.includes(drvPath) &&
          typeof status === "number" &&
          VERIFIED_HYDRA_FAILURES.has(status)
        ) {
          return {
            buildId: candidate.buildId,
            drvPath,
            status,
            url: url.toString(),
          };
        }
      } catch (error) {
        core.notice(
          `Hydra build ${candidate.buildId} could not be verified (${errorMessage(error)}); ignoring it.`,
        );
        return null;
      }
    }

    return null;
  }
}

const hydra = new HydraClient(
  runtime.CONFIGURATION_SYSTEM,
  runtime.HYDRA_USER_AGENT,
);

export async function exactHydraFailure(
  drvPaths: string[],
): Promise<HydraFailure | null> {
  return hydra.exactFailure(drvPaths);
}

export function failedDerivation(output: string): string {
  return (
    validDerivationPaths(
      DIRECT_FAILURE_PATTERNS.map(
        (pattern) => output.match(pattern)?.groups?.drvPath,
      ),
    )[0] ?? ""
  );
}

export function lastBuildingDerivation(output: string): string {
  return (
    validDerivationPaths(
      Array.from(
        output.matchAll(BUILDING_DERIVATION_PATTERN),
        (match) => match.groups?.drvPath,
      ),
    ).at(-1) ?? ""
  );
}

function transientFailure(output: string): TransientFailure | undefined {
  return TRANSIENT_FAILURES.find(({ pattern }) => pattern.test(output));
}

export function failedPackageOutput(output: string, failedDrv: string): string {
  const failedName = derivationName(failedDrv);
  if (!failedName) {
    return output;
  }
  const failedPackage = failedName.replace(/-[^a-z].*$/iu, "");

  // Match Nix's versionless builder label to exclude other packages' warnings
  return output
    .split("\n")
    .filter((line) => {
      const packageName = /^([^\s>]+)>/u.exec(line)?.[1];
      return (
        !packageName ||
        failedName === packageName ||
        failedPackage === packageName
      );
    })
    .join("\n");
}

// The macOS test assumes its outgoing chunk fills the OS buffer and can hang
// https://github.com/twisted/twisted/issues/12151
export function isKnownDarwinTwistedTcpTimeout(
  output: string,
  failedDrv: string,
  system: string,
): boolean {
  return (
    system.endsWith("-darwin") &&
    derivationName(failedDrv) === "python3.13-twisted-26.4.0" &&
    /TestTimeoutError: reactor still running after 120\.0 seconds/u.test(
      output,
    ) &&
    /twisted\.internet\.test\.test_tcp\.AbortConnectionTests_AsyncioSelectorReactorTests\.test_fullWriteBuffer(?:\s|$)/u.test(
      output,
    )
  );
}

export function containsTransientFailure(output: string): boolean {
  return transientFailure(output) !== undefined;
}

async function reportRunnerResources(): Promise<void> {
  try {
    const snapshot = await runCommand([
      "timeout",
      "5s",
      "sh",
      "-c",
      `date --utc --iso-8601=seconds
awk '/^(MemAvailable|SwapTotal|SwapFree|Shmem):/' /proc/meminfo
awk '$1 == "oom_kill"' /proc/vmstat
cat /proc/pressure/memory
df -h / /nix /nix/build "$RUNNER_TEMP"
ps -eo comm,rss --sort=-rss | head -n 8`,
    ]);
    if (snapshot.exitCode !== 0) {
      core.warning(
        `Runner resource snapshot exited with ${snapshot.exitCode}.`,
      );
    }
  } catch (error) {
    core.warning(`Could not report runner resources: ${String(error)}`);
  }
}

async function runBuild(targetDrv: string): Promise<BuildExecution> {
  const command = [
    "nix",
    "build",
    "--print-build-logs",
    ...Object.entries({
      "max-jobs": runtime.BUILD_MAX_JOBS,
      cores: runtime.BUILD_CORES,
    }).flatMap(([name, value]) => ["--option", name, String(value)]),
    `${targetDrv}^*`,
  ];
  // Keep evidence in streamed logs if Linux loses contact with GitHub
  const monitorResources =
    process.platform === "linux" && process.env.GITHUB_ACTIONS === "true";
  if (monitorResources) {
    await reportRunnerResources();
  }
  const { processHandle, result } = capturedCommand(command);
  if (monitorResources) {
    const resourceInterval = setInterval(() => {
      void reportRunnerResources();
    }, 60_000);
    const stopMonitoring = () => clearInterval(resourceInterval);
    void processHandle.exited.then(stopMonitoring, stopMonitoring);
  }
  const startSeconds =
    runtime.BUILD_STARTED_AT_EPOCH ?? Math.floor(Date.now() / 1000);
  const remainingMilliseconds = Math.max(
    0,
    (startSeconds + runtime.BUILD_TIMEOUT_SECONDS) * 1000 - Date.now(),
  );
  let timedOut = false;
  let timeoutHandle: ReturnType<typeof setTimeout> | undefined;

  const timeout = new Promise<void>((resolve) => {
    timeoutHandle = setTimeout(resolve, remainingMilliseconds);
  });
  const completedBeforeTimeout = await Promise.race([
    processHandle.exited.then(() => true),
    timeout.then(() => false),
  ]);

  if (!completedBeforeTimeout) {
    timedOut = true;
    core.error(
      `Nix build exceeded its ${runtime.BUILD_TIMEOUT_SECONDS}s soft deadline.`,
    );
    processHandle.kill("SIGTERM");

    const stopped = await Promise.race([
      processHandle.exited.then(() => true),
      Bun.sleep(10_000).then(() => false),
    ]);
    if (!stopped) {
      processHandle.kill("SIGKILL");
    }
  } else if (timeoutHandle) {
    clearTimeout(timeoutHandle);
  }

  const completed = await result;
  return {
    exitCode: timedOut ? 124 : completed.exitCode,
    output: stripVTControlCharacters(completed.output),
    timedOut,
  };
}

async function classifyBuild(build: BuildExecution): Promise<BuildResult> {
  if (build.exitCode === 0) {
    return createResult();
  }

  const timeoutDrv = lastBuildingDerivation(build.output);
  const failedDrv = failedDerivation(build.output) || timeoutDrv;
  if (build.timedOut) {
    return createResult({
      exitCode: build.exitCode,
      failedDrv,
      failureKind: "timeout",
      failureSummary:
        "The build reached its soft deadline after caching completed derivations.",
      retryable: true,
      timedOut: true,
      timeoutDrv,
    });
  }

  const context: FailureContext = {
    failedDrv,
    hydraFailure: failedDrv ? await exactHydraFailure([failedDrv]) : null,
    output: build.output,
    system: runtime.CONFIGURATION_SYSTEM,
    transientFailure: transientFailure(
      failedPackageOutput(build.output, failedDrv),
    ),
  };
  const rule = FAILURE_RULES.find(({ matches }) => matches(context));
  if (!rule) {
    throw new Error("No build failure classification rule matched.");
  }

  return createResult({
    exitCode: build.exitCode,
    failedDrv,
    failureKind: rule.kind,
    failureSummary: rule.summary(context),
    hydraUrl: context.hydraFailure?.url ?? "",
    retryable: rule.retryable,
    timeoutDrv,
  });
}

async function orchestrateBuild(): Promise<BuildResult> {
  const target = CONFIGURATION_TARGETS[runtime.CONFIGURATION_KIND](
    runtime.CONFIGURATION_NAME,
  );
  console.log(`Resolving ${target} once for both the preflight and build.`);
  const evaluation = await runCommand([
    "nix",
    "eval",
    "--raw",
    `${target}.drvPath`,
  ]);
  if (evaluation.exitCode !== 0) {
    return createResult({
      exitCode: evaluation.exitCode,
      failureKind: "deterministic",
      failureSummary: "The configuration target could not be evaluated.",
    });
  }

  const parsedTarget = v.safeParse(
    DerivationPathSchema,
    evaluation.stdout.trim(),
  );
  if (!parsedTarget.success) {
    throw new Error(
      `Nix returned an invalid target derivation: ${evaluation.stdout.trim()}`,
    );
  }
  const targetDrv = parsedTarget.output;
  console.log(`Resolved target derivation: ${targetDrv}`);

  const plan = await runCommand([
    "nix",
    "build",
    "--dry-run",
    `${targetDrv}^*`,
  ]);
  if (plan.exitCode !== 0) {
    return createResult({
      exitCode: plan.exitCode,
      failureKind: "deterministic",
      failureSummary: "Nix could not compute the configuration build plan.",
    });
  }

  const knownFailure = await exactHydraFailure(plannedDerivations(plan.output));
  if (knownFailure) {
    const failureSummary =
      `Nixpkgs Hydra already failed this exact derivation ` +
      `(status ${knownFailure.status}); compilation was skipped.`;
    core.error(failureSummary);
    return createResult({
      exitCode: 1,
      failedDrv: knownFailure.drvPath,
      failureKind: "hydra",
      failureSummary,
      hydraUrl: knownFailure.url,
    });
  }

  return classifyBuild(await runBuild(targetDrv));
}

async function main(): Promise<number> {
  let result: BuildResult;
  try {
    await enforceStartupDelay({
      bypassForDevelopment: developmentBypassRequested(),
      isGitHubActions: process.env.GITHUB_ACTIONS === "true",
    });
    result = await orchestrateBuild();
  } catch (error) {
    const failureSummary = `Build orchestration failed: ${errorMessage(error)}`;
    core.error(failureSummary);
    result = createResult({
      exitCode: 1,
      failureKind: "unknown",
      failureSummary,
    });
  }

  writeResult(result);
  await writeSummary(result);
  return result.exitCode;
}

if (import.meta.main) {
  process.exitCode = await main();
}
