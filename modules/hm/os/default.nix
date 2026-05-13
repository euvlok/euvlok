{
  lib,
  inputs,
  osClass,
  ...
}:
{
  imports = [
    inputs.catppuccin-trivial.homeModules.catppuccin
  ]
  ++ lib.optionals (osClass == "nixos") [ ./firefox.nix ];

  catppuccin.vscode.profiles.default.enable = lib.mkDefault false;
}
