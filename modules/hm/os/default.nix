{
  lib,
  inputs,
  osConfig,
  ...
}:
let
  isLinux = osConfig.nixpkgs.hostPlatform.isLinux;
in
{
  imports = [
    inputs.catppuccin-trivial.homeModules.catppuccin
  ]
  ++ lib.optionals isLinux [ ./firefox.nix ];
}
