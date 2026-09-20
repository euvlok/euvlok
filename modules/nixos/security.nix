{ config, lib, ... }:
{
  options.euvlok.nixos.security.enable = lib.options.mkEnableOption "the shared security policy" // {
    default = true;
  };

  config = lib.modules.mkIf config.euvlok.nixos.security.enable {
    security = {
      rtkit.enable = config.services.xserver.enable;
      polkit.enable = true;
      sudo.enable = false;
      sudo-rs.enable = true;
      sudo-rs.execWheelOnly = true;
    };
  };
}
