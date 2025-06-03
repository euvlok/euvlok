{ config, ... }:
{
  security = {
    rtkit.enable = config.services.xserver.enable;
    polkit.enable = true;
    sudo.enable = false;
    sudo-rs.enable = true;
    sudo-rs.execWheelOnly = true;
  };
}
