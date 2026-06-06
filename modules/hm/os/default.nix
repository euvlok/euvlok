{
  lib,
  inputs,
  config,
  osClass,
  ...
}:
{
  imports = [
    inputs.catppuccin-trivial.homeModules.catppuccin
  ]
  ++ lib.lists.optionals (osClass == "nixos") [ ./firefox.nix ];

  catppuccin.vscode.profiles.default.enable = lib.modules.mkDefault false;
  catppuccin.autoEnable = lib.modules.mkDefault config.catppuccin.enable;
}
