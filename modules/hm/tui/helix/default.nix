{ lib, config, ... }:
{
  imports = [
    ./languages.nix
    ./settings.nix
  ];

  options.hm.helix.enable = lib.options.mkEnableOption "Helix";

  config = lib.modules.mkIf config.hm.helix.enable {
    programs.helix.enable = true;
  };
}
