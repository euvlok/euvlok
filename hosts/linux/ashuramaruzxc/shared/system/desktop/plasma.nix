{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.euvlok.nixos.plasma.enable {
    environment.systemPackages = lib.attrsets.attrValues {
      inherit (pkgs.unstable.kdePackages) krohnkite;
    };
  };
}
