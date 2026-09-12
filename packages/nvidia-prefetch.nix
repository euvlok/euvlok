{
  lib,
  coreutils,
  curl,
  git,
  nix-update,
  nvidia-driver,
  writeShellApplication,
}:

writeShellApplication {
  name = "nvidia-prefetch";
  runtimeInputs = [
    coreutils
    curl
    git
    nix-update
  ];
  text =
    builtins.replaceStrings
      [
        "@currentVersion@"
        "@updateArgs@"
      ]
      [
        nvidia-driver.version
        (lib.escapeShellArgs nvidia-driver.updateArgs)
      ]
      (builtins.readFile ./nvidia-prefetch.sh);
}
