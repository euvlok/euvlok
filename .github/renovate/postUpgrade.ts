#!/usr/bin/env node
import { execFileSync } from "node:child_process";

type Command = Readonly<{ command: string; args: readonly string[] }>;
type Task = Readonly<{ commands: readonly Command[] }>;

const sourcePackages = [
  "linux-rt-upscaler",
  "lsfg-vk",
  "nvidia-driver",
  "catppuccin-gtk",
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
    (name) =>
      [
        name,
        {
          commands: [
            {
              command: "nix",
              args: [
                "run",
                "--impure",
                "--expr",
                `let
                  flake = builtins.getFlake (toString ./.);
                  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
                  package = flake.packages.x86_64-linux.${name};
                  version = ${
                    name === "catppuccin-gtk"
                      ? '"--version=branch=" + package.src.rev'
                      : '"--version=skip"'
                  };
                in pkgs.writeShellApplication {
                  name = "euvlok-package-update";
                  runtimeInputs = [ pkgs.nixfmt ];
                  text = pkgs.lib.strings.escapeShellArgs (package.updateScript ++ [
                    version
                    "--src-only"
                    "--system=x86_64-linux"
                  ]);
                }`,
              ],
            },
          ],
        },
      ] as const,
  ),
]);

const name = process.argv[2] ?? "missing";
const task = tasks.get(name);
if (!task) throw new Error(`Unsupported Renovate post-upgrade task: ${name}`);
for (const { command, args } of task.commands) {
  execFileSync(command, args, { stdio: "inherit" });
}
