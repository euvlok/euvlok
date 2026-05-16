{
  pkgs,
  lib,
  ...
}:
{
  # programs.ghidra.enable = true;
  home.packages =
    (builtins.attrValues {
      inherit (pkgs.unstable)
        nuclei
        cent
        binwalk
        valgrind
        netscanner
        zap
        amass
        httpx
        feroxbuster
        dalfox
        websocat
        ;
    })
    ++ lib.lists.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      pkgs.unstable.autopsy
    ];
}
