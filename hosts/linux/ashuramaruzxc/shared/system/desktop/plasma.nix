{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.modules.mkIf config.euvlok.nixos.plasma.enable {
    environment.systemPackages = lib.attrsets.attrValues {
      inherit (pkgs.kdePackages) krohnkite;
    };
  };
}
