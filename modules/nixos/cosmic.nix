{
  inputs,
  lib,
  config,
  ...
}:
{
  disabledModules = [ "services/desktop-managers/cosmic.nix" ];

  imports = [
    ("${inputs.nixpkgs-unstable-small.outPath}/nixos/modules/services/desktop-managers/cosmic.nix")
  ];

  options.nixos.cosmic.enable = lib.mkEnableOption "COSMIC";

  config = lib.mkIf config.nixos.cosmic.enable {
    services = {
      displayManager.cosmic-greeter.enable = true;
      desktopManager.cosmic.enable = true;
    };
  };
}
