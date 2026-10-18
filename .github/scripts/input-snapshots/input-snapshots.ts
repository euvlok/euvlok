#!/usr/bin/env bun
// Build and verify input snapshots for the current native configurations
// Reduce Home Manager's automatic imports against each original native graph
// Union the retained imports, then validate and retrace that common graph
// Only the resulting file-access closure is pruned and published
// The release bundle contains both consumer locks and manifest.json
// Use restore --manifest manifest.json before changing modules or inputs

import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { createReadStream, type Stats } from "node:fs";
import {
  chmod,
  copyFile,
  cp,
  lstat,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  readlink,
  rm,
  stat,
  symlink,
  writeFile,
} from "node:fs/promises";
import { constants } from "node:os";
import {
  basename,
  dirname,
  isAbsolute,
  join,
  relative,
  resolve,
} from "node:path";
import { createInterface } from "node:readline";
import { pathToFileURL } from "node:url";
import { isDeepStrictEqual, parseArgs, type ParseArgsConfig } from "node:util";
import {
  discoverHomeModules,
  type HomeModuleSelection,
  minimizeHomeModules,
  renderHomeModules,
} from "./home-manager-modules";

const LOCK_FILES = ["flake.lock", "flake-modules/users/flake.lock"] as const;
const OPERATIONS = ["read", "stat", "list", "link"] as const;
const NATIVE_SYSTEMS = [
  "aarch64-darwin",
  "aarch64-linux",
  "x86_64-linux",
] as const;
const NOTICE_PATTERN =
  /^(?:licen[sc]es?|copying|copyright|notices?|unlicense)(?:[._-].*)?$/i;

type Locked = {
  type: string;
  narHash: string;
  dir?: string;
  [attribute: string]: string | number | undefined;
};
type LockNode = {
  locked?: Locked;
  inputs?: Record<string, string | string[]>;
};
type Lock = { root: string; nodes: Record<string, LockNode> };
type Locks = Record<string, Lock>;
type Alias = { lock: string; node: string; locked: Locked };
type Source = {
  id: string;
  source: string;
  aliases: Alias[];
  protected?: boolean;
};
type Inventory = {
  version: number;
  lockDigest: string;
  locks: Locks;
  sources: Record<string, Source>;
};
type Archive = { path: string; inputs?: Record<string, Archive> };
type Operation = (typeof OPERATIONS)[number];
type Usage = Record<Operation, Set<string>> & {
  whole: boolean;
  modules?: HomeModuleSelection;
  lockDigest?: string;
};
type SerializedUsage = Record<Operation, string[]> & { whole: boolean };
type ModulePlan = {
  version: 1;
  lockDigest: string;
  sources: Record<string, HomeModuleSelection>;
};
type ModuleReduction = ModulePlan & {
  system: string;
  attempts: Record<string, number>;
};
type Trace = {
  system: string;
  modules: ModulePlan;
  sources: Record<string, SerializedUsage>;
};
type Evaluation = Record<string, Record<string, string>>;
type Pruning =
  | { pruned: false; reason: string }
  | {
      pruned: true;
      beforeBytes: number;
      afterBytes: number;
      keptFiles: number;
      placeholders: number;
      moduleImports?: { before: number; after: number };
    };
type Candidate =
  | { setting: string; timedOut: true }
  | { setting: string; failed: number; reason: string }
  | { setting: string; bytes: number; seconds: number };
type PackResult = {
  id: string;
  upstreamHash: string;
  sourceHash: string;
  candidates: Candidate[];
  asset: string;
  type: "file" | "tarball";
  bytes: number;
  sha256: string;
  setting?: string;
  pruning?: Pruning;
  tarBytes?: number;
};
type ManifestSource =
  | { protected: true; reason: string; aliases: Alias[] }
  | (PackResult & { url: string; aliases: Alias[]; protected?: false });
type Manifest = {
  version: number;
  lockDigest: string;
  sources: Record<string, ManifestSource>;
};
type RunOptions = {
  env?: NodeJS.ProcessEnv;
  timeout?: number;
  inherit?: boolean;
};

class CommandError extends Error {
  constructor(
    readonly exitCode: number,
    readonly stderr: string,
    readonly timedOut: boolean,
  ) {
    super(timedOut ? "Command timed out" : `Command exited with ${exitCode}`);
  }
}

async function run(
  command: string,
  args: string[],
  options: RunOptions = {},
): Promise<string> {
  return new Promise((complete, reject) => {
    const child = spawn(command, args, {
      env: options.env ?? process.env,
      stdio: options.inherit ? ["ignore", "inherit", "inherit"] : "pipe",
    });
    child.stdin?.end();
    const stdout: Buffer[] = [];
    const stderr: Buffer[] = [];
    child.stdout?.on("data", (chunk: Buffer) => stdout.push(chunk));
    child.stderr?.on("data", (chunk: Buffer) => stderr.push(chunk));
    let timedOut = false;
    const timer = options.timeout
      ? setTimeout(() => {
          timedOut = true;
          child.kill("SIGKILL");
        }, options.timeout * 1000)
      : undefined;
    child.once("error", (error) => {
      clearTimeout(timer);
      reject(error);
    });
    child.once("close", (code, signal) => {
      clearTimeout(timer);
      if (code !== 0 || timedOut) {
        reject(
          new CommandError(
            code ?? -(signal ? constants.signals[signal] : 1),
            Buffer.concat(stderr).toString("utf8"),
            timedOut,
          ),
        );
      } else {
        complete(Buffer.concat(stdout).toString("utf8"));
      }
    });
  });
}

async function nixJson<T>(...args: string[]): Promise<T> {
  return JSON.parse(await run("nix", ["--no-lazy-trees", ...args]));
}

async function readJson<T>(path: string): Promise<T> {
  return JSON.parse(await readFile(path, "utf8"));
}

function ordered(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(ordered);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value)
        .sort(([left], [right]) => compare(left, right))
        .map(([key, item]) => [key, ordered(item)]),
    );
  }
  return value;
}

// Python's original inventory identity used sorted keys and ASCII JSON
function canonicalJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  if (value !== null && typeof value === "object") {
    return `{${Object.entries(value)
      .sort(([left], [right]) => compare(left, right))
      .map(([key, item]) => `${canonicalJson(key)}:${canonicalJson(item)}`)
      .join(",")}}`;
  }
  return JSON.stringify(value).replace(/[\u0080-\uffff]/g, (character) => {
    return `\\u${character.charCodeAt(0).toString(16).padStart(4, "0")}`;
  });
}

async function writeJson(path: string, value: unknown): Promise<void> {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, `${JSON.stringify(ordered(value), null, 2)}\n`);
}

function compare(left: string, right: string): number {
  return Buffer.compare(Buffer.from(left), Buffer.from(right));
}

function required<T>(value: T | undefined, description: string): T {
  if (value === undefined) throw new Error(`Missing ${description}`);
  return value;
}

async function maybeLstat(path: string): Promise<Stats | undefined> {
  try {
    return await lstat(path);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return undefined;
    throw error;
  }
}

async function fileHash(path: string): Promise<string> {
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(path)) hash.update(chunk);
  return hash.digest("hex");
}

export function sourceId(locked: Locked): string {
  // Equal source trees share one asset even when several locks name them
  return createHash("sha256").update(locked.narHash).digest("hex").slice(0, 24);
}

export function mainNixpkgsSource(locks: Locks): string {
  const lock = required(locks["flake.lock"], "root lock graph");
  function follow(path: string[], active = new Set<string>()): string {
    const identity = JSON.stringify(path);
    if (active.has(identity)) {
      throw new Error("Cyclic follows reference for the main Nixpkgs input");
    }
    let node = lock.root;
    for (const name of path) {
      const target = required(
        lock.nodes[node]?.inputs?.[name],
        `${node}/${name}`,
      );
      node = Array.isArray(target)
        ? follow(target, new Set([...active, identity]))
        : target;
    }
    return node;
  }
  return sourceId(
    required(lock.nodes[follow(["nixpkgs"])]?.locked, "main pin"),
  );
}

function archiveSources(
  lock: Lock,
  archive: Archive,
  relativeLock: string,
  sources: Record<string, Source>,
): void {
  const visited = new Set<string>();
  function visit(name: string, tree: Archive): void {
    if (visited.has(name)) return;
    visited.add(name);
    const node = required(lock.nodes[name], `${relativeLock}:${name}`);
    if (node.locked) {
      const key = sourceId(node.locked);
      sources[key] ??= {
        id: key,
        source: tree.path,
        aliases: [],
      };
      const entry = sources[key];
      entry.aliases.push({
        lock: relativeLock,
        node: name,
        locked: node.locked,
      });
    }
    for (const [input, target] of Object.entries(node.inputs ?? {})) {
      // Follows references reuse an already reachable lock node
      if (Array.isArray(target)) continue;
      const child = required(
        tree.inputs?.[input],
        `archive input ${relativeLock}:${name}/${input}`,
      );
      visit(target, child);
    }
  }
  visit(lock.root, archive);
  const missing = Object.keys(lock.nodes).filter((name) => !visited.has(name));
  if (missing.length) {
    throw new Error(
      `Unarchived lock nodes in ${relativeLock}: ${missing.sort()}`,
    );
  }
}

export async function inventory(
  project: string,
  output: string,
): Promise<void> {
  const sources: Record<string, Source> = {};
  const locks: Locks = {};
  let projectHash: string | undefined;
  for (const relativeLock of LOCK_FILES) {
    const directory = join(project, dirname(relativeLock));
    const lock = await readJson<Lock>(join(project, relativeLock));
    const archive = await nixJson<Archive>(
      "flake",
      "archive",
      "--json",
      "--no-write-lock-file",
      `path:${directory}`,
    );
    projectHash ??= (await run("nix", ["hash", "path", archive.path])).trim();
    locks[relativeLock] = lock;
    archiveSources(lock, archive, relativeLock, sources);
  }
  const protectedSource = mainNixpkgsSource(locks);
  for (const [key, entry] of Object.entries(sources)) {
    // Protect every alias of the main input, including the users partition
    entry.protected = key === protectedSource;
  }
  const lockDigest = createHash("sha256")
    .update(canonicalJson({ locks, projectHash }))
    .digest("hex");
  await writeJson(output, { version: 1, lockDigest, locks, sources });
  console.log(
    `Inventoried ${Object.keys(sources).length} distinct sources; main Nixpkgs stays upstream`,
  );
}

function nixString(value: string): string {
  return JSON.stringify(value).replaceAll("${", "\\${");
}

class BuildGraphChanged extends Error {}

export async function evaluate(
  project: string,
  system: string,
  nix = "nix",
  env = process.env,
  expected?: Evaluation,
): Promise<Evaluation> {
  async function apply<T>(
    attribute: string,
    expression?: string,
    directory = project,
  ): Promise<T> {
    return JSON.parse(
      await run(
        nix,
        [
          "--extra-experimental-features",
          "parallel-eval",
          "--no-lazy-trees",
          "--no-eval-cache",
          "--eval-cores",
          "2",
          "--cores",
          "2",
          "--max-jobs",
          "2",
          "eval",
          "--json",
          "--no-write-lock-file",
          `path:${directory}#${attribute}`,
          ...(expression ? ["--apply", expression] : []),
        ],
        { env },
      ),
    );
  }
  // Release each host's evaluator heap before starting the next one
  const names = await apply<string[]>(
    `hostChecksBySystem.${system}`,
    "builtins.attrNames",
  );
  if (
    expected &&
    !isDeepStrictEqual(names, Object.keys(expected.hosts ?? {}).sort(compare))
  ) {
    throw new BuildGraphChanged("Native host membership changed");
  }
  const hosts: Record<string, string> = {};
  const output: Evaluation = { hosts };
  for (const name of names) {
    hosts[name] = await apply(
      `hostChecksBySystem.${system}.${nixString(name)}`,
    );
    // Reject a trial before evaluating unrelated hosts when a root differs
    if (expected && hosts[name] !== expected.hosts?.[name]) {
      throw new BuildGraphChanged(`Host derivation changed: ${name}`);
    }
  }
  for (const group of ["packages", "checks", "devShells"]) {
    output[group] = await apply(
      `${group}.${system}`,
      "builtins.mapAttrs (_: value: value.drvPath)",
    );
    if (
      expected &&
      !sameModuleBuilds(
        { [group]: expected[group] ?? {} },
        { [group]: required(output[group], `evaluation ${group}`) },
      )
    ) {
      throw new BuildGraphChanged(`Native derivations changed: ${group}`);
    }
  }
  output.userChecks = await apply(
    `checks.${system}`,
    "builtins.mapAttrs (_: value: value.drvPath)",
    join(project, "flake-modules/users"),
  );
  return output;
}

function evaluationDifferences(
  expected: Evaluation,
  actual: Evaluation,
): Record<string, string[]> {
  const differences: Record<string, string[]> = {};
  for (const group of new Set([
    ...Object.keys(expected),
    ...Object.keys(actual),
  ])) {
    const before = expected[group] ?? {};
    const after = actual[group] ?? {};
    const names = [...new Set([...Object.keys(before), ...Object.keys(after)])]
      .filter((name) => before[name] !== after[name])
      .sort(compare);
    if (names.length) differences[group] = names;
  }
  return differences;
}

function sameModuleBuilds(expected: Evaluation, actual: Evaluation): boolean {
  const differences = evaluationDifferences(expected, actual);
  // Generated lock checks embed the consumer locks themselves
  // Final verification builds their replacements instead of comparing paths
  for (const group of ["checks", "userChecks"]) {
    if (
      expected[group]?.["check-flake-file"] &&
      actual[group]?.["check-flake-file"]
    ) {
      differences[group] = (differences[group] ?? []).filter(
        (name) => name !== "check-flake-file",
      );
    }
  }
  return Object.values(differences).every((names) => names.length === 0);
}

async function copyProject(
  project: string,
  destination: string,
): Promise<void> {
  await cp(project, destination, {
    recursive: true,
    dereference: false,
    verbatimSymlinks: true,
    filter: (path) =>
      ![".git", ".jj", "node_modules", "result"].includes(basename(path)),
  });
}

async function removeModuleWork(directory: string): Promise<void> {
  // Copies of store sources retain read-only directory modes
  // Make only our private copies removable without following their symlinks
  for await (const path of walk(directory)) {
    const info = await lstat(path);
    if (info.isDirectory()) await chmod(path, info.mode | 0o700);
  }
  await rm(directory, { recursive: true, force: true });
}

async function validateModulePlan(
  data: Inventory,
  plan: ModulePlan,
): Promise<void> {
  if (plan.version !== 1 || plan.lockDigest !== data.lockDigest) {
    throw new Error(
      "Module plan belongs to a different input/configuration snapshot",
    );
  }
  const expected = Object.entries(data.sources)
    .filter(([, source]) =>
      source.aliases.some((alias) => alias.locked.repo === "home-manager"),
    )
    .map(([key]) => key)
    .sort(compare);
  if (!isDeepStrictEqual(Object.keys(plan.sources).sort(compare), expected)) {
    throw new Error("Module plan does not cover every Home Manager source");
  }
  for (const [key, selection] of Object.entries(plan.sources)) {
    const source = required(data.sources[key], `module source ${key}`);
    if (!(await maybeLstat(source.source))) {
      source.source = await fetchSource(source);
    }
    await renderHomeModules(source.source, selection);
  }
}

async function moduleConsumer(
  data: Inventory,
  plan: ModulePlan,
  work: string,
  consumer: string,
): Promise<Inventory> {
  const candidate = structuredClone(data);
  for (const [key, selection] of Object.entries(plan.sources)) {
    if (isDeepStrictEqual(selection.kept, selection.candidates)) continue;
    const original = required(data.sources[key], `module source ${key}`);
    const source = join(work, key, "source");
    if (!(await maybeLstat(source))) {
      await mkdir(dirname(source), { recursive: true });
      await cp(original.source, source, {
        recursive: true,
        dereference: false,
        verbatimSymlinks: true,
      });
      await chmod(join(source, "modules"), 0o755);
      await chmod(join(source, "modules/modules.nix"), 0o644);
    }
    await writeFile(
      join(source, "modules/modules.nix"),
      await renderHomeModules(original.source, selection),
    );
    // Materialize an immutable, correctly hashed candidate before changing locks
    // Never reuse the upstream hash for a modified tree
    const tree = await nixJson<{ narHash: string; source: string }>(
      "eval",
      "--impure",
      "--json",
      "--expr",
      `let tree = builtins.fetchTree { type = "path"; path = ${nixString(source)}; }; in { inherit (tree) narHash; source = tree.outPath; }`,
    );
    required(candidate.sources[key], `module source ${key}`).source =
      tree.source;
    for (const alias of original.aliases) {
      if (alias.locked.name !== undefined) {
        throw new Error(
          "Home Manager path candidates cannot preserve a custom input name",
        );
      }
      const locked: Locked = {
        type: "path",
        path: tree.source,
        narHash: tree.narHash,
      };
      for (const attribute of ["lastModified", "rev", "revCount", "dir"]) {
        if (alias.locked[attribute] !== undefined) {
          locked[attribute] = alias.locked[attribute];
        }
      }
      required(
        candidate.locks[alias.lock]?.nodes[alias.node],
        `module alias ${alias.lock}:${alias.node}`,
      ).locked = locked;
    }
  }
  for (const [path, lock] of Object.entries(candidate.locks)) {
    await writeJson(join(consumer, path), lock);
  }
  return candidate;
}

export async function reduceModules(
  project: string,
  inventoryPath: string,
  system: string,
  output: string,
): Promise<void> {
  if (!(NATIVE_SYSTEMS as readonly string[]).includes(system)) {
    throw new Error(`Unsupported native system: ${system}`);
  }
  const data = await readJson<Inventory>(inventoryPath);
  await mkdir(output, { recursive: true });
  const baseline = await evaluate(project, system);
  await writeJson(join(output, "baseline.json"), baseline);
  const reduction: ModuleReduction = {
    version: 1,
    lockDigest: data.lockDigest,
    system,
    sources: {},
    attempts: {},
  };
  for (const [key, source] of Object.entries(data.sources)) {
    if (source.aliases.some((alias) => alias.locked.repo === "home-manager")) {
      reduction.sources[key] = await discoverHomeModules(source.source);
    }
  }
  await validateModulePlan(data, reduction);
  const work = await mkdtemp(join(output, "module-search-"));
  try {
    const consumer = join(work, "project");
    await copyProject(project, consumer);
    for (const [key, selection] of Object.entries(reduction.sources)) {
      const result = await minimizeHomeModules(
        selection.candidates,
        async (kept) => {
          const trial = structuredClone(reduction);
          required(trial.sources[key], `module source ${key}`).kept = kept;
          await moduleConsumer(data, trial, work, consumer);
          try {
            return sameModuleBuilds(
              baseline,
              await evaluate(consumer, system, "nix", process.env, baseline),
            );
          } catch (error) {
            if (
              !(error instanceof CommandError) &&
              !(error instanceof BuildGraphChanged)
            ) {
              throw error;
            }
            return false;
          }
        },
        (kept, attempts) =>
          console.log(
            `${key}: retained ${kept.length}/${selection.candidates.length} automatic imports after ${attempts} evaluations`,
          ),
      );
      selection.kept = result.kept;
      reduction.attempts[key] = result.attempts;
    }
    await moduleConsumer(data, reduction, work, consumer);
    if (!sameModuleBuilds(baseline, await evaluate(consumer, system))) {
      throw new Error(
        `Final Home Manager reduction changed builds on ${system}`,
      );
    }
    await writeJson(join(output, "modules.json"), reduction);
  } finally {
    await removeModuleWork(work);
  }
}

function requireNativeSystems(systems: Set<string>): void {
  if (!isDeepStrictEqual([...systems].sort(), [...NATIVE_SYSTEMS].sort())) {
    throw new Error(
      `Incomplete native results: expected ${NATIVE_SYSTEMS}, got ${[...systems]}`,
    );
  }
}

export async function mergeModules(
  inventoryPath: string,
  directory: string,
  output: string,
): Promise<void> {
  const data = await readJson<Inventory>(inventoryPath);
  const systems = new Set<string>();
  let merged: ModulePlan | undefined;
  for (const child of await readdir(directory, { withFileTypes: true })) {
    if (!child.isDirectory()) continue;
    const path = join(directory, child.name, "modules.json");
    if (!(await maybeLstat(path))) continue;
    const reduction = await readJson<ModuleReduction>(path);
    if (systems.has(reduction.system)) {
      throw new Error(`Duplicate native module result: ${reduction.system}`);
    }
    systems.add(reduction.system);
    await validateModulePlan(data, reduction);
    if (!merged) {
      merged = {
        version: 1,
        lockDigest: data.lockDigest,
        sources: structuredClone(reduction.sources),
      };
      continue;
    }
    for (const [key, selection] of Object.entries(merged.sources)) {
      const other = required(reduction.sources[key], `module source ${key}`);
      if (
        selection.loaderHash !== other.loaderHash ||
        !isDeepStrictEqual(selection.candidates, other.candidates)
      ) {
        throw new Error(`Native module candidate sets differ for ${key}`);
      }
      const kept = new Set([...selection.kept, ...other.kept]);
      selection.kept = selection.candidates.filter((path) => kept.has(path));
    }
  }
  requireNativeSystems(systems);
  await writeJson(output, required(merged, "native module plans"));
}

function emptyUsage(): Usage {
  return {
    read: new Set(),
    stat: new Set(),
    list: new Set(),
    link: new Set(),
    whole: false,
  };
}

export async function trace(
  project: string,
  inventoryPath: string,
  system: string,
  nix: string,
  output: string,
  modulesPath: string,
  baselinePath: string,
): Promise<void> {
  const original = await readJson<Inventory>(inventoryPath);
  const modules = await readJson<ModulePlan>(modulesPath);
  const expected = await readJson<Evaluation>(baselinePath);
  await validateModulePlan(original, modules);
  await mkdir(output, { recursive: true });
  const work = await mkdtemp(join(output, "module-trace-"));
  try {
    const consumer = join(work, "project");
    await copyProject(project, consumer);
    const data = await moduleConsumer(original, modules, work, consumer);
    await traceSources(consumer, data, system, nix, output, expected, modules);
  } finally {
    await removeModuleWork(work);
  }
}

async function traceSources(
  project: string,
  data: Inventory,
  system: string,
  nix: string,
  output: string,
  expected: Evaluation,
  modules: ModulePlan,
): Promise<void> {
  const log = join(output, "accesses.jsonl");
  if (await maybeLstat(log)) {
    throw new Error(`Refusing to reuse an existing trace: ${log}`);
  }
  const baseline = await evaluate(project, system, nix, {
    ...process.env,
    EUVLOK_SOURCE_TRACE: log,
  });
  if (!(await maybeLstat(log))?.size) {
    throw new Error("Evaluator produced no source trace; use input-trace-nix");
  }
  // A union of native keep sets can reactivate interactions between modules
  // Validate and retrace that common graph rather than merging search traces
  if (!sameModuleBuilds(expected, baseline)) {
    throw new Error(
      `Common Home Manager import graph changed builds on ${system}`,
    );
  }
  await writeJson(join(output, "baseline.json"), expected);
  const roots = new Map(
    Object.entries(data.sources).map(([key, entry]) => [entry.source, key]),
  );
  const usage = Object.fromEntries(
    Object.keys(data.sources).map((key) => [key, emptyUsage()]),
  );
  const records = createInterface({
    input: createReadStream(log),
    crlfDelay: Infinity,
  });
  for await (const line of records) {
    const record = JSON.parse(line) as {
      op: Operation;
      path: string;
      virtual?: boolean;
    };
    const path = resolve(record.path);
    for (let parent = path; ; parent = dirname(parent)) {
      const key = roots.get(parent);
      if (key) {
        if (record.virtual) {
          throw new Error(
            `Input access has no physical path: ${path}; disable lazy trees`,
          );
        }
        required(usage[key], `usage ${key}`)[record.op].add(
          relative(parent, path) || ".",
        );
        break;
      }
      if (dirname(parent) === parent) break;
    }
  }
  const derivations = [
    ...new Set(
      Object.values(baseline).flatMap((group) => Object.values(group)),
    ),
  ].sort(compare);
  // Already-present store paths can become build inputs without evaluator
  // reads, so include the recursive derivation closure as well
  const references = await run("nix-store", [
    "--query",
    "--requisites",
    ...derivations,
  ]);
  for (const reference of references.trim().split("\n")) {
    const key = roots.get(reference);
    if (key) required(usage[key], `usage ${key}`).whole = true;
  }
  const serialized = Object.fromEntries(
    Object.entries(usage).map(([key, value]) => [
      key,
      {
        whole: value.whole,
        ...Object.fromEntries(
          OPERATIONS.map((op) => [op, [...value[op]].sort(compare)]),
        ),
      },
    ]),
  );
  await writeJson(join(output, "usage.json"), {
    system,
    modules,
    sources: serialized,
  });
  console.log(`Traced ${derivations.length} derivations on ${system}`);
}

async function* walk(directory: string): AsyncGenerator<string> {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    yield path;
    if (entry.isDirectory()) yield* walk(path);
  }
}

function inside(root: string, path: string): boolean {
  const suffix = relative(root, path);
  return suffix !== ".." && !suffix.startsWith("../") && !isAbsolute(suffix);
}

export async function pruneSource(
  source: string,
  destination: string,
  usage: Usage,
  flakeDirs: Set<string>,
): Promise<Pruning> {
  const reducedModules =
    usage.modules &&
    !isDeepStrictEqual(usage.modules.kept, usage.modules.candidates);
  if (usage.whole) {
    if (reducedModules) {
      throw new Error(
        "Cannot remove module imports from a whole-tree build dependency",
      );
    }
    return { pruned: false, reason: "Whole-tree build dependency" };
  }
  const loader = reducedModules
    ? await renderHomeModules(
        source,
        required(usage.modules, "module selection"),
      )
    : undefined;
  const content = new Set([...usage.read, ...usage.link]);
  const metadata = new Set([...usage.stat, ...content, ...usage.list, "."]);
  // Preserve directory entry names/types even if their contents were unused
  for (const path of usage.list) {
    for (const name of await readdir(join(source, path))) {
      metadata.add(join(path, name));
    }
  }
  for (const directory of flakeDirs) {
    for (const name of ["flake.nix", "flake.lock"]) {
      const path = join(directory, name);
      if (await maybeLstat(join(source, path))) {
        content.add(path);
        metadata.add(path);
      }
    }
  }
  let beforeBytes = 0;
  let afterBytes = 0;
  let keptFiles = 0;
  let placeholders = 0;
  const notices = new Set<string>();
  async function preserveNotice(path: string): Promise<void> {
    const pending = [path];
    while (pending.length) {
      const item = required(pending.pop(), "pending notice");
      const suffix = relative(source, item);
      if (notices.has(suffix)) continue;
      notices.add(suffix);
      let parent = source;
      let redirected = false;
      for (const part of suffix.split("/").slice(0, -1)) {
        parent = join(parent, part);
        if ((await lstat(parent)).isSymbolicLink()) {
          pending.push(parent);
          const target = resolve(
            dirname(parent),
            await readlink(parent),
            relative(parent, item),
          );
          if (inside(source, target)) pending.push(target);
          redirected = true;
          break;
        }
      }
      if (redirected) continue;
      const info = await maybeLstat(item);
      if (!info) continue;
      content.add(suffix);
      metadata.add(suffix);
      if (info.isSymbolicLink()) {
        const target = resolve(dirname(item), await readlink(item));
        if (inside(source, target)) pending.push(target);
      } else if (info.isDirectory()) {
        pending.push(...(await readdir(item)).map((name) => join(item, name)));
      }
    }
  }
  // Preserve upstream distribution notices and their in-tree symlink targets
  for await (const path of walk(source)) {
    const info = await lstat(path);
    if (info.isFile()) beforeBytes += info.size;
    if (NOTICE_PATTERN.test(basename(path))) await preserveNotice(path);
  }
  for (const path of [...metadata]) {
    for (let parent = dirname(path); parent !== "."; parent = dirname(parent)) {
      metadata.add(parent);
    }
  }
  await mkdir(destination);
  const depth = (path: string) => (path === "." ? 0 : path.split("/").length);
  for (const suffix of [...metadata].sort(
    (left, right) => depth(left) - depth(right) || compare(left, right),
  )) {
    if (!inside(source, resolve(source, suffix))) {
      throw new Error(`Source access escapes its input: ${suffix}`);
    }
    const path = join(source, suffix);
    const target = join(destination, suffix);
    const info = await lstat(path);
    if (info.isSymbolicLink()) {
      await symlink(await readlink(path), target);
    } else if (info.isDirectory()) {
      await mkdir(target, { recursive: true });
    } else if (content.has(suffix)) {
      if (suffix === "modules/modules.nix" && loader !== undefined) {
        await writeFile(target, loader);
        afterBytes += Buffer.byteLength(loader);
      } else {
        await copyFile(path, target);
        afterBytes += info.size;
      }
      await chmod(target, info.mode & 0o777);
      keptFiles++;
    } else {
      await writeFile(target, "");
      await chmod(target, info.mode & 0o100 ? 0o755 : 0o644);
      placeholders++;
    }
  }
  return {
    pruned: true,
    beforeBytes,
    afterBytes,
    keptFiles,
    placeholders,
    ...(usage.modules
      ? {
          moduleImports: {
            before: usage.modules.candidates.length,
            after: usage.modules.kept.length,
          },
        }
      : {}),
  };
}

export async function mergeUsage(
  directory: string,
  key: string,
): Promise<Usage> {
  const merged = emptyUsage();
  let modules: ModulePlan | undefined;
  const systems = new Set<string>();
  for (const child of await readdir(directory, { withFileTypes: true })) {
    if (!child.isDirectory()) continue;
    const path = join(directory, child.name, "usage.json");
    if (!(await maybeLstat(path))) continue;
    const value = await readJson<Trace>(path);
    if (systems.has(value.system)) {
      throw new Error(`Duplicate native trace: ${value.system}`);
    }
    if (value.modules?.version !== 1) {
      throw new Error("Trace is missing its verified Home Manager module plan");
    }
    if (modules && !isDeepStrictEqual(modules, value.modules)) {
      throw new Error("Native traces used different Home Manager module plans");
    }
    modules = value.modules;
    systems.add(value.system);
    const usage = required(value.sources[key], `trace source ${key}`);
    merged.whole ||= usage.whole;
    for (const op of OPERATIONS) {
      for (const path of usage[op]) merged[op].add(path);
    }
  }
  requireNativeSystems(systems);
  const plan = required(modules, "verified module plan");
  merged.lockDigest = plan.lockDigest;
  if (plan.sources[key]) merged.modules = plan.sources[key];
  return merged;
}

async function fetchSource(entry: Source): Promise<string> {
  const locked = { ...required(entry.aliases[0], "source alias").locked };
  delete locked.dir;
  const result = await nixJson<{ narHash: string; sourcePath: string }>(
    "eval",
    "--impure",
    "--json",
    "--expr",
    `let tree = builtins.fetchTree (builtins.fromJSON ${nixString(JSON.stringify(locked))}); in { inherit (tree) narHash; sourcePath = tree.outPath; }`,
  );
  if (result.narHash !== locked.narHash) {
    throw new Error("Fetched source differs from its upstream lock");
  }
  return result.sourcePath;
}

async function deterministicTar(
  source: string,
  destination: string,
): Promise<void> {
  // GNU tar normalizes ownership, modes, times, ordering, and PAX headers
  // Restrict the transform to member names so symlink targets stay unchanged
  await run(process.platform === "darwin" ? "gtar" : "tar", [
    "--format=pax",
    "--sort=name",
    "--mtime=@0",
    "--owner=0",
    "--group=0",
    "--numeric-owner",
    "--mode=a=rX,u+w",
    "--hard-dereference",
    "--pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime",
    "--transform=flags=r;s,^\\.,source,",
    "-cf",
    destination,
    "-C",
    source,
    ".",
  ]);
}

export async function pack(
  inventoryPath: string,
  key: string,
  output: string,
  timeout = 900,
  traces?: string,
): Promise<void> {
  const data = await readJson<Inventory>(inventoryPath);
  if (key === mainNixpkgsSource(data.locks)) {
    throw new Error("The main Nixpkgs input must not be pruned or repacked");
  }
  const entry = required(data.sources[key], `source ${key}`);
  let source = await fetchSource(entry);
  await mkdir(output, { recursive: true });
  let expectedHash = required(entry.aliases[0], "source alias").locked.narHash;
  const result: PackResult = {
    id: key,
    upstreamHash: expectedHash,
    sourceHash: expectedHash,
    candidates: [],
    asset: "",
    type: "tarball",
    bytes: 0,
    sha256: "",
  };
  let asset: string;
  if ((await stat(source)).isFile()) {
    // A file input is not automatically unpacked by Nix's file fetcher
    asset = join(output, `${key}.file`);
    await copyFile(source, asset);
    const fetched = await nixJson<{ hash: string }>(
      "flake",
      "prefetch",
      "--json",
      `file+${pathToFileURL(asset).href}`,
    );
    if (fetched.hash !== expectedHash) {
      throw new Error("Mirrored file failed Nix source-hash verification");
    }
    result.asset = basename(asset);
    result.type = "file";
    result.bytes = (await stat(asset)).size;
  } else {
    // Hosted compression runs on Linux, where Bash can enforce RLIMIT_AS
    // macOS rejects finite address-space limits; do not silently omit the cap
    if (process.platform !== "linux") {
      throw new Error(
        "Run source compression on Linux to enforce its memory cap",
      );
    }
    const meminfo = await readFile("/proc/meminfo", "utf8");
    const available = Number(
      required(
        /^MemAvailable:\s+(\d+)/m.exec(meminfo)?.[1],
        "available memory",
      ),
    );
    const memoryLimit = Math.max(
      512 * 1024 ** 2,
      available * 1024 - 2 * 1024 ** 3,
    );
    const work = await mkdtemp(join(output, "input-snapshot-"));
    try {
      if (traces) {
        const pruned = join(work, "pruned");
        const usage = await mergeUsage(traces, key);
        if (usage.lockDigest !== data.lockDigest) {
          throw new Error(
            "Native traces belong to a different input/configuration snapshot",
          );
        }
        result.pruning = await pruneSource(
          source,
          pruned,
          usage,
          new Set(entry.aliases.map((alias) => alias.locked.dir ?? ".")),
        );
        if (result.pruning.pruned) {
          source = pruned;
          expectedHash = (await run("nix", ["hash", "path", source])).trim();
          result.sourceHash = expectedHash;
        }
      }
      const tar = join(work, "source.tar");
      await deterministicTar(source, tar);
      result.tarBytes = (await stat(tar)).size;
      const settings: [string, string[]][] = [
        ["19", ["-19"]],
        ["22", ["--ultra", "-22"]],
        ["max", ["--max"]],
      ];
      let best: { bytes: number; setting: string; path: string } | undefined;
      for (const [setting, flags] of settings) {
        const candidate = join(work, `source-${setting}.tar.zst`);
        const started = performance.now();
        // Nix's decoder caps window memory at 128 MiB; retain --long=27
        // Apply the memory limit before exec replaces Bash with the compressor
        try {
          await run(
            "bash",
            [
              "--noprofile",
              "--norc",
              "-c",
              'ulimit -v "$1" && shift && exec "$@"',
              "input-compressor",
              String(Math.floor(memoryLimit / 1024)),
              "zstd",
              ...flags,
              "--long=27",
              "-T1",
              "-q",
              tar,
              "-o",
              candidate,
            ],
            { timeout },
          );
        } catch (error) {
          if (!(error instanceof CommandError)) throw error;
          result.candidates.push(
            error.timedOut
              ? { setting, timedOut: true }
              : {
                  setting,
                  failed: error.exitCode,
                  reason: error.stderr.trim().slice(0, 512),
                },
          );
          continue;
        }
        const fetched = await nixJson<{ hash: string }>(
          "flake",
          "prefetch",
          "--json",
          `tarball+${pathToFileURL(candidate).href}`,
        );
        if (fetched.hash !== expectedHash) {
          throw new Error(`${key}/${setting} changed the unpacked source tree`);
        }
        const bytes = (await stat(candidate)).size;
        result.candidates.push({
          setting,
          bytes,
          seconds: Math.round(performance.now() - started) / 1000,
        });
        if (!best || bytes < best.bytes)
          best = { bytes, setting, path: candidate };
      }
      if (!best)
        throw new Error(`No compression candidate completed for ${key}`);
      asset = join(output, `${key}.tar.zst`);
      await copyFile(best.path, asset);
      result.asset = basename(asset);
      result.bytes = best.bytes;
      result.setting = best.setting;
    } finally {
      await rm(work, { recursive: true, force: true });
    }
  }
  result.sha256 = await fileHash(asset);
  await writeJson(join(output, `${key}.json`), result);
  console.log(`Verified ${result.asset}: ${result.bytes} bytes`);
}

export function snapshotLocked(
  original: Locked,
  result: PackResult,
  url: string,
): Locked {
  const locked: Locked = { type: result.type, url, narHash: result.sourceHash };
  for (const attribute of ["lastModified", "rev", "revCount", "dir", "name"]) {
    if (original[attribute] !== undefined)
      locked[attribute] = original[attribute];
  }
  return locked;
}

export async function snapshotLocks(
  inventoryPath: string,
  assets: string,
  baseUrl: string,
  output: string,
): Promise<void> {
  const data = await readJson<Inventory>(inventoryPath);
  const manifest: Manifest = {
    version: 1,
    lockDigest: data.lockDigest,
    sources: {},
  };
  const protectedSource = mainNixpkgsSource(data.locks);
  for (const [key, entry] of Object.entries(data.sources)) {
    if (key === protectedSource) {
      manifest.sources[key] = {
        protected: true,
        reason: "Main Nixpkgs remains pinned to its upstream source",
        aliases: entry.aliases,
      };
      continue;
    }
    const result = await readJson<PackResult>(join(assets, `${key}.json`));
    const asset = join(assets, result.asset);
    if ((await fileHash(asset)) !== result.sha256) {
      throw new Error(`Asset checksum mismatch: ${basename(asset)}`);
    }
    const url = `${baseUrl.replace(/\/+$/, "")}/${basename(asset)}`;
    manifest.sources[key] = { ...result, url, aliases: entry.aliases };
    for (const alias of entry.aliases) {
      const node = required(
        data.locks[alias.lock]?.nodes[alias.node],
        `${alias.lock}:${alias.node}`,
      );
      // Keep original references so normal updates still consult upstream
      node.locked = snapshotLocked(alias.locked, result, url);
    }
  }
  for (const [path, lock] of Object.entries(data.locks)) {
    await writeJson(join(output, path), lock);
  }
  await writeJson(join(output, "manifest.json"), manifest);
}

export async function restore(
  project: string,
  manifestPath: string,
): Promise<void> {
  const manifest = await readJson<Manifest>(manifestPath);
  const locks: Locks = {};
  for (const path of LOCK_FILES)
    locks[path] = await readJson(join(project, path));
  let restored = 0;
  for (const source of Object.values(manifest.sources)) {
    if (source.protected) continue;
    for (const alias of source.aliases) {
      const node = locks[alias.lock]?.nodes[alias.node];
      // Leave any input already updated independently untouched
      if (
        node &&
        isDeepStrictEqual(
          node.locked,
          snapshotLocked(alias.locked, source, source.url),
        )
      ) {
        node.locked = alias.locked;
        restored++;
      }
    }
  }
  for (const [path, lock] of Object.entries(locks)) {
    await writeJson(join(project, path), lock);
  }
  console.log(`Restored ${restored} upstream lock entries`);
}

export async function verify(
  project: string,
  inventoryPath: string,
  assets: string,
  baseline: string,
  system: string,
  output: string,
): Promise<void> {
  await mkdir(output, { recursive: true });
  const work = await mkdtemp(join(output, "input-consumer-"));
  try {
    const consumer = join(work, "project");
    await copyProject(project, consumer);
    await snapshotLocks(
      inventoryPath,
      assets,
      pathToFileURL(assets).href,
      consumer,
    );
    const actual = await evaluate(consumer, system);
    const expected = await readJson<Evaluation>(baseline);
    await writeJson(join(output, "actual.json"), actual);
    const differences = evaluationDifferences(expected, actual);
    // The manifest check embeds the repository, including changed locks
    // Require it to pass instead of retaining its old source path
    const builtChecks: [string, string][] = [];
    for (const [group, directory] of [
      ["checks", consumer],
      ["userChecks", join(consumer, "flake-modules/users")],
    ] as const) {
      if (
        expected[group]?.["check-flake-file"] &&
        actual[group]?.["check-flake-file"]
      ) {
        differences[group] = (differences[group] ?? []).filter(
          (name) => name !== "check-flake-file",
        );
        builtChecks.push([group, directory]);
      }
    }
    for (const [group, names] of Object.entries(differences)) {
      if (!names.length) delete differences[group];
    }
    await writeJson(join(output, "verification.json"), { system, differences });
    if (Object.keys(differences).length) {
      throw new Error(
        `Snapshot changed derivations on ${system}: ${JSON.stringify(differences)}`,
      );
    }
    for (const [, directory] of builtChecks) {
      await run(
        "nix",
        [
          "--extra-experimental-features",
          "parallel-eval",
          "--eval-cores",
          "2",
          "--cores",
          "2",
          "--max-jobs",
          "2",
          "build",
          "--no-link",
          "--no-write-lock-file",
          `path:${directory}#checks.${system}.check-flake-file`,
        ],
        { inherit: true },
      );
    }
    await writeJson(join(output, "verification.json"), {
      system,
      differences,
      builtChecks: builtChecks.map(([group]) => `${group}.check-flake-file`),
    });
    console.log(
      `Snapshot preserves native derivations and passes manifest checks on ${system}`,
    );
  } finally {
    await rm(work, { recursive: true, force: true });
  }
}

const COMMAND_OPTIONS = {
  inventory: ["project", "output"],
  reduce: ["project", "inventory", "system", "output"],
  modules: ["inventory", "reductions", "output"],
  pack: ["inventory", "id", "output", "timeout", "traces"],
  locks: ["inventory", "assets", "base-url", "output"],
  trace: [
    "project",
    "inventory",
    "system",
    "nix",
    "output",
    "modules",
    "baseline",
  ],
  verify: ["project", "inventory", "assets", "baseline", "system", "output"],
  restore: ["project", "manifest"],
} as const;

async function main(): Promise<void> {
  const [command, ...args] = process.argv.slice(2);
  if (!command || command === "--help" || command === "-h") {
    console.log(
      "Usage: bun input-snapshots.ts <inventory|reduce|modules|trace|pack|locks|verify|restore> [options]\n" +
        "Build and verify input snapshots for the current native configurations\n" +
        "Run pack on Linux with GNU tar and zstd available\n" +
        "Use restore --manifest manifest.json before changing modules or inputs",
    );
    if (!command) process.exitCode = 2;
    return;
  }
  if (!Object.hasOwn(COMMAND_OPTIONS, command)) {
    throw new Error(`Unknown snapshot command: ${command}`);
  }
  const names = COMMAND_OPTIONS[command as keyof typeof COMMAND_OPTIONS];
  const options: NonNullable<ParseArgsConfig["options"]> = Object.fromEntries([
    ...names.map((name) => [name, { type: "string" as const }]),
    ["help", { type: "boolean" as const, short: "h" }],
  ]);
  const { values } = parseArgs({ args, options, strict: true });
  if (values.help) {
    console.log(
      `Usage: bun input-snapshots.ts ${command} ${names.map((name) => `--${name} <value>`).join(" ")}`,
    );
    return;
  }
  function argument(name: string, fallback?: string): string {
    const value = values[name] ?? fallback;
    if (typeof value !== "string" || !value) {
      throw new Error(`Required option: --${name}`);
    }
    return value;
  }
  const path = (name: string, fallback?: string) =>
    resolve(argument(name, fallback));
  switch (command) {
    case "inventory":
      await inventory(path("project", process.cwd()), path("output"));
      break;
    case "reduce":
      await reduceModules(
        path("project", process.cwd()),
        path("inventory"),
        argument("system"),
        path("output"),
      );
      break;
    case "modules":
      await mergeModules(path("inventory"), path("reductions"), path("output"));
      break;
    case "trace":
      await trace(
        path("project", process.cwd()),
        path("inventory"),
        argument("system"),
        argument("nix"),
        path("output"),
        path("modules"),
        path("baseline"),
      );
      break;
    case "pack": {
      const timeout = Number(argument("timeout", "900"));
      if (!Number.isSafeInteger(timeout) || timeout <= 0) {
        throw new Error("--timeout must be a positive integer in seconds");
      }
      await pack(
        path("inventory"),
        argument("id"),
        path("output"),
        timeout,
        values.traces ? path("traces") : undefined,
      );
      break;
    }
    case "locks":
      await snapshotLocks(
        path("inventory"),
        path("assets"),
        argument("base-url"),
        path("output"),
      );
      break;
    case "verify":
      await verify(
        path("project", process.cwd()),
        path("inventory"),
        path("assets"),
        path("baseline"),
        argument("system"),
        path("output"),
      );
      break;
    case "restore":
      await restore(path("project", process.cwd()), path("manifest"));
      break;
  }
}

if (import.meta.main) {
  main().catch((error: unknown) => {
    if (error instanceof CommandError) {
      console.error(error.stderr || error.message);
      process.exitCode = error.exitCode || 1;
    } else {
      console.error(error instanceof Error ? error.message : String(error));
      process.exitCode = 1;
    }
  });
}
