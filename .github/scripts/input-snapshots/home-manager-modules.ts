import { createHash } from "node:crypto";
import { readFile, readdir } from "node:fs/promises";
import { join } from "node:path";

export type HomeModuleSelection = {
  loaderHash: string;
  candidates: string[];
  kept: string[];
};

const MODULE_DIRECTORIES = ["services", "programs"] as const;
const SAFE_MODULE_PATH = /^(services|programs)\/[A-Za-z0-9._+-]+$/;
const SUFFIX_DEFINITION = '  hasNixSuffix = lib.hasSuffix ".nix";\n';

// Support the pinned loader's exact conditional, not arbitrary Nix syntax
// Keeping the minimal branch in this guard makes upstream changes fail closed
const MINIMAL_BRANCH = `    (
      if minimal then
        [
          ./programs/bash.nix
          ./programs/autojump.nix # Dependency of bash module
          ./programs/zsh
          ./programs/ion.nix
          ./programs/nushell.nix
          ./services/window-managers/i3-sway/default.nix # Dependency of home-cursor module
        ]
      else
`;
const AUTOMATIC_IMPORTS = `        lib.concatMap
          (
            dir:
            lib.pipe (builtins.readDir dir) [
              (lib.filterAttrs (path: kind: kind == "directory" || (kind == "regular" && hasNixSuffix path)))
              (lib.mapAttrsToList (path: _kind: lib.path.append dir path))
            ]
          )
          [
            ./services
            ./programs
          ]`;
const AUTOMATIC_BRANCH = `${MINIMAL_BRANCH}${AUTOMATIC_IMPORTS}\n    )`;

function unsupportedLoader(): never {
  throw new Error("Unsupported Home Manager modules/modules.nix loader");
}

function automaticImportsOffset(loader: string): number {
  const branch = loader.indexOf(AUTOMATIC_BRANCH);
  const suffix = loader.indexOf(SUFFIX_DEFINITION);
  if (
    branch < 0 ||
    loader.indexOf(AUTOMATIC_BRANCH, branch + 1) >= 0 ||
    suffix < 0 ||
    suffix >= branch ||
    loader.indexOf(SUFFIX_DEFINITION, suffix + 1) >= 0 ||
    loader.indexOf(AUTOMATIC_IMPORTS) !== branch + MINIMAL_BRANCH.length ||
    loader.indexOf(AUTOMATIC_IMPORTS, branch + MINIMAL_BRANCH.length + 1) >= 0
  ) {
    unsupportedLoader();
  }
  return branch + MINIMAL_BRANCH.length;
}

async function readLoader(source: string): Promise<{
  loader: string;
  loaderHash: string;
  offset: number;
}> {
  const bytes = await readFile(join(source, "modules", "modules.nix"));
  const loader = bytes.toString("utf8");
  if (!Buffer.from(loader).equals(bytes)) unsupportedLoader();
  return {
    loader,
    loaderHash: createHash("sha256").update(bytes).digest("hex"),
    offset: automaticImportsOffset(loader),
  };
}

function validateModulePaths(paths: string[], description: string): void {
  if (!Array.isArray(paths)) {
    throw new Error(`Invalid Home Manager ${description}`);
  }
  let previousDirectory = -1;
  let previousName: Buffer | undefined;
  for (const path of paths) {
    if (typeof path !== "string" || !SAFE_MODULE_PATH.test(path)) {
      throw new Error(`Invalid Home Manager ${description} path`);
    }
    const slash = path.indexOf("/");
    const directory = path.slice(0, slash) === "services" ? 0 : 1;
    const name = path.slice(slash + 1);
    const nameBytes = Buffer.from(name);
    if (
      name === "." ||
      name === ".." ||
      directory < previousDirectory ||
      (directory === previousDirectory &&
        previousName !== undefined &&
        Buffer.compare(previousName, nameBytes) >= 0)
    ) {
      throw new Error(`Unordered or duplicate Home Manager ${description}`);
    }
    previousDirectory = directory;
    previousName = nameBytes;
  }
}

async function moduleCandidates(source: string): Promise<string[]> {
  const candidates: string[] = [];
  for (const directory of MODULE_DIRECTORIES) {
    const entries = await readdir(join(source, "modules", directory), {
      withFileTypes: true,
    });
    entries.sort((left, right) =>
      left.name < right.name ? -1 : left.name > right.name ? 1 : 0,
    );
    for (const entry of entries) {
      const name = entry.name;
      if (entry.isDirectory() || (entry.isFile() && name.endsWith(".nix"))) {
        candidates.push(`${directory}/${name}`);
      }
    }
  }
  validateModulePaths(candidates, "candidates");
  return candidates;
}

// Candidates match readDir's immediate regular .nix files and directories
// Symlinks are excluded, and services precede programs as in the original loader
export async function discoverHomeModules(
  source: string,
): Promise<HomeModuleSelection> {
  const { loaderHash } = await readLoader(source);
  const candidates = await moduleCandidates(source);
  return { loaderHash, candidates, kept: [...candidates] };
}

// Bind a plan to both the loader bytes and the complete automatic namespace
// Only the automatic else expression changes, leaving core/minimal imports intact
export async function renderHomeModules(
  source: string,
  selection: HomeModuleSelection,
): Promise<string> {
  if (!selection || typeof selection !== "object") {
    throw new Error("Invalid Home Manager module selection");
  }
  validateModulePaths(selection.candidates, "candidates");
  validateModulePaths(selection.kept, "kept modules");
  const candidates = [...selection.candidates];
  const kept = [...selection.kept];
  const expectedHash = selection.loaderHash;
  const { loader, loaderHash, offset } = await readLoader(source);
  if (expectedHash !== loaderHash) {
    throw new Error("Home Manager module selection loader hash mismatch");
  }
  const actualCandidates = await moduleCandidates(source);
  if (
    candidates.length !== actualCandidates.length ||
    candidates.some((path, index) => path !== actualCandidates[index])
  ) {
    throw new Error("Home Manager module selection namespace mismatch");
  }
  let cursor = 0;
  for (const path of kept) {
    while (cursor < candidates.length && candidates[cursor] !== path) cursor++;
    if (cursor === candidates.length) {
      throw new Error(
        "Home Manager kept modules are not a candidate subsequence",
      );
    }
    cursor++;
  }
  if (kept.length === candidates.length) return loader;
  const explicitImports =
    kept.length === 0
      ? "        [ ]"
      : `        [\n${kept.map((path) => `          ./${path}`).join("\n")}\n        ]`;
  return (
    loader.slice(0, offset) +
    explicitImports +
    loader.slice(offset + AUTOMATIC_IMPORTS.length)
  ).replace(SUFFIX_DEFINITION, "");
}

// The oracle must compare the selected native build graphs against the original
// baseline, not merely accept successful evaluation
// A rejected group is split, and all retained groups are retried after removals
// The result is one-deletion-minimal, not necessarily a global minimum
export async function minimizeHomeModules(
  candidates: string[],
  equivalent: (kept: string[]) => Promise<boolean>,
  progress?: (kept: string[], attempts: number) => void,
): Promise<{ kept: string[]; attempts: number }> {
  if (!Array.isArray(candidates)) {
    throw new Error("Invalid Home Manager minimization candidates");
  }
  const seen = new Set<string>();
  for (const path of candidates) {
    if (typeof path !== "string" || path.length === 0 || seen.has(path)) {
      throw new Error("Invalid Home Manager minimization candidates");
    }
    seen.add(path);
  }
  let kept = [...candidates];
  let attempts = 0;
  let changed = false;
  async function removeGroup(group: string[]): Promise<void> {
    if (group.length === 0) return;
    const removed = new Set(group);
    const proposed = kept.filter((path) => !removed.has(path));
    attempts++;
    const accepted = (await equivalent([...proposed])) === true;
    if (accepted) {
      kept = proposed;
      changed = true;
    }
    // Report only the last accepted subset, including after rejected attempts
    progress?.([...kept], attempts);
    if (!accepted && group.length > 1) {
      const middle = Math.floor(group.length / 2);
      await removeGroup(group.slice(0, middle));
      await removeGroup(group.slice(middle));
    }
  }
  do {
    changed = false;
    await removeGroup([...kept]);
  } while (changed && kept.length > 0);
  return { kept, attempts };
}
