{
  pkgs,
  ...
}:
{
  # programs.ghidra.enable = true;
  home.packages = builtins.attrValues {
    inherit (pkgs.unstable)
      autopsy
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
  };
}
