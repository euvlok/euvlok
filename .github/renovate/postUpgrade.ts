#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";

type Command = Readonly<{ command: string; args: readonly string[] }>;
type Task = Readonly<{ commands: readonly Command[]; prepare?: () => void }>;
type SourcePackage = Readonly<{
  name: string;
  subpackages?: readonly string[];
  prepare?: () => void;
}>;

function updateThemeDate(): void {
  const file = "packages/catppuccin-gtk.nix";
  const content = readFileSync(file, "utf8");
  const revision = content.match(/^\s*rev = "([a-f0-9]{40})";$/m)?.[1];
  if (!revision) {
    throw new Error("Cannot find the GTK theme revision");
  }
  const date = execFileSync(
    "gh",
    [
      "api",
      `repos/Fausto-Korpsvart/Catppuccin-GTK-Theme/commits/${revision}`,
      "--jq",
      ".commit.committer.date[:10]",
    ],
    { encoding: "utf8", stdio: ["ignore", "pipe", "inherit"] },
  ).trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    throw new Error("Cannot determine the GTK theme commit date");
  }
  const updated = content.replace(
    /version = "unstable-[0-9-]+";/,
    `version = "unstable-${date}";`,
  );
  writeFileSync(file, updated);
}

const sourcePackages: readonly SourcePackage[] = [
  { name: "linux-rt-upscaler" },
  { name: "lsfg-vk" },
  {
    name: "nvidia-driver",
    subpackages: ["aarch64", "open", "settings", "persistenced"],
  },
  { name: "catppuccin-gtk", prepare: updateThemeDate },
];
const sourceArguments = [
  "--flake",
  "--version=skip",
  "--src-only",
  "--system",
  "x86_64-linux",
];
const tasks = new Map<string, Task>([
  // Renovate's Nix manager only maintains flake.lock, so refresh devenv too
  ["flake", { commands: [{ command: "devenv", args: ["update"] }] }],
  [
    "determinate",
    {
      commands: [
        { command: "nix", args: ["run", ".#write-flake"] },
        { command: "nix", args: ["flake", "update", "determinate"] },
      ],
    },
  ],
  ...sourcePackages.map(
    ({ name, subpackages = [], prepare }) =>
      [
        name,
        {
          commands: [
            {
              command: "nix-update",
              args: [
                ...sourceArguments,
                ...subpackages.flatMap((subpackage) => [
                  "--subpackage",
                  subpackage,
                ]),
                name,
              ],
            },
          ],
          ...(prepare ? { prepare } : {}),
        },
      ] as const,
  ),
]);

const name = process.argv[2] ?? "missing";
const task = tasks.get(name);
if (!task) throw new Error(`Unsupported Renovate post-upgrade task: ${name}`);
task.prepare?.();
for (const { command, args } of task.commands) {
  execFileSync(command, args, { stdio: "inherit" });
}
