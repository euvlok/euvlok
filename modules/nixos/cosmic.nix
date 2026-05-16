{
  lib,
  config,
  ...
}:
{
  #! temp remove cosmic from nixos-unstable
  # disabledModules = [ "services/desktop-managers/cosmic.nix" ];

  # imports = [
  #   ("${inputs.nixpkgs-unstable-small.outPath}/nixos/modules/services/desktop-managers/cosmic.nix")
  # ];

  options.nixos.cosmic.enable = lib.options.mkEnableOption "COSMIC";

  config = lib.modules.mkIf config.nixos.cosmic.enable {
    nixos.gui.enable = lib.modules.mkDefault true;

    services = {
      displayManager.cosmic-greeter.enable = true;
      desktopManager.cosmic.enable = true;
    };
  };
}
