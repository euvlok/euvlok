{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./languages.nix
    ./settings.nix
  ];

  options.euvlok.home.helix.enable = lib.options.mkEnableOption "Helix";

  config = lib.modules.mkIf config.euvlok.home.helix.enable {
    programs.helix = {
      enable = true;
      extraPackages = [ pkgs.unstable.rumdl ];
    };
  };
}
