{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.nixpkgs.hostPlatform) isLinux;

  flakeInputs = lib.attrsets.filterAttrs (_: lib.types.isType "flake") inputs;
  nixPathEntries = lib.attrsets.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  registry = lib.attrsets.mapAttrs (_: flake: { inherit flake; }) flakeInputs;

  buildParallelism =
    lib.trivial.pipe
      (pkgs.runCommand "nix-build-parallelism" { } ''
        ${pkgs.writeShellScript "get-nix-build-parallelism" ''
          ${pkgs.python3}/bin/python3 - <<'PY'
          import json
          import os
          import platform
          import subprocess


          def clamp(value, lower, upper):
              return max(lower, min(value, upper))


          def memory_gib():
              if platform.system() == "Linux":
                  with open("/proc/meminfo", encoding="utf-8") as meminfo:
                      for line in meminfo:
                          if line.startswith("MemTotal:"):
                              return int(line.split()[1]) // 1024 // 1024

              if platform.system() == "Darwin":
                  output = subprocess.check_output(["/usr/sbin/sysctl", "-n", "hw.memsize"], text=True)
                  return int(output) // 1024 // 1024 // 1024

              return 8


          def parse_cpu_list(cpu_list):
              cpus = 0
              for part in cpu_list.split(","):
                  if "-" in part:
                      start, end = part.split("-", 1)
                      cpus += int(end) - int(start) + 1
                  else:
                      cpus += 1

              return cpus


          def cpu_threads():
              if platform.system() == "Linux":
                  try:
                      with open("/sys/devices/system/cpu/online", encoding="utf-8") as online:
                          return parse_cpu_list(online.read().strip())
                  except OSError:
                      pass

              return os.cpu_count() or 1


          threads = cpu_threads()
          memory = memory_gib()

          memory_budget = max(1, memory * 70 // 100)

          memory_jobs = max(1, (memory_budget + 7) // 8)
          cpu_jobs = clamp((threads + 7) // 8, 1, 8)
          max_jobs = min(memory_jobs, cpu_jobs)

          cores = max(1, threads // max_jobs)

          print(json.dumps({"max-jobs": max_jobs, "cores": cores}))
          PY
        ''} > $out
      '')
      [
        lib.strings.fileContents
        builtins.fromJSON
      ];
in
{
  config = (
    lib.modules.mkMerge [
      (lib.modules.mkIf isLinux {
        # Add inputs to legacy (nix2) channels, making legacy nix commands consistent
        environment.etc = lib.attrsets.optionalAttrs isLinux (
          lib.attrsets.mapAttrs' (name: value: {
            name = "nix/path/${name}";
            value.source = value.flake;
          }) config.nix.registry
        );
      })
      (lib.modules.mkIf isLinux { nix.registry = lib.modules.mkForce registry; })
      {
        nix = {
          settings = {
            experimental-features = "nix-command flakes";
            cores = lib.modules.mkDefault buildParallelism.cores;
            max-jobs = lib.modules.mkDefault buildParallelism."max-jobs";

            substituters = [
              "https://devenv.cachix.org"
              "https://euvlok.cachix.org"
              "https://eupkgs.cachix.org"
              "https://hyprland.cachix.org"
              "https://nix-community.cachix.org"
              "https://nixos-raspberrypi.cachix.org"
              "https://cache.flox.dev"
            ];
            trusted-public-keys = [
              "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
              "euvlok.cachix.org-1:cmFWCSs7rxPiyE1qfaJn8TY7QaRoGOrzKuNvtGw2gcU="
              "eupkgs.cachix.org-1:V9Y0HdASNNSU9U6EkXhR1j85bZGRtNgW7wSyTiQrwGU="
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
              "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
            ];
            nix-path = nixPathEntries;
          }
          // lib.attrsets.optionalAttrs isLinux {
            # Disable global registry
            flake-registry = "";
          };
          # Obviously, we don't want channels; they're imperatively managed. Disabling
          # them means that the `nixpkgs` instance with which the host was built is used
          # as the "de facto" channel when referring to `<nixpkgs>`
          channel.enable = false;

          # Flake Inputs
          nixPath = nixPathEntries;
        };
      }
    ]
  );
}
