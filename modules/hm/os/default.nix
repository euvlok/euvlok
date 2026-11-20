{ euvlokInputs }:
{
  config,
  lib,
  ...
}:
{
  imports = [
    euvlokInputs.catppuccin.homeModules.catppuccin
    ./firefox.nix
  ];

  catppuccin.autoEnable = lib.modules.mkDefault config.catppuccin.enable;
}
