{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  getCpuCores = pkgs.writeShellScript "get-cpu-cores" ''
    ${pkgs.python3}/bin/python3 -c "import os; print(os.cpu_count() or 4)"
  '';

  buildCores = lib.max 1 (
    (lib.toInt (
      lib.fileContents (
        pkgs.runCommand "cpu-cores" { } ''
          ${getCpuCores} > $out
        ''
      )
    ))
    - 2
  );

  # Memory limits for launchd (in bytes)
  getSystemMemory = pkgs.writeShellScript "get-system-memory" ''
    ${pkgs.python3}/bin/python3 -c "
    import os
    mem_bytes = os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES')
    # 80% for soft limit, 90% for hard limit
    soft_limit = int(mem_bytes * 0.80)
    hard_limit = int(mem_bytes * 0.90)
    print(f'{soft_limit},{hard_limit}')
    "
  '';
  memoryLimits = lib.splitString "," (
    lib.fileContents (
      pkgs.runCommand "memory-limits" { } ''
        ${getSystemMemory} > $out
      ''
    )
  );
in
{
  imports = [ inputs.determinate.darwinModules.default ];
  launchd.daemons.nix-daemon.serviceConfig = {
    SoftResourceLimits = {
      NumberOfProcesses = buildCores * 512;
      ResidentSetSize = lib.toInt (lib.elemAt memoryLimits 0); # Dynamic memory soft limit (80%)
    };
    HardResourceLimits = {
      NumberOfProcesses = buildCores * 1024;
      ResidentSetSize = lib.toInt (lib.elemAt memoryLimits 1); # Dynamic memory hard limit (90%)
    };
  };
}
