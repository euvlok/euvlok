{ config, ... }:
{
  security = {
    rtkit.enable = config.services.xserver.enable;
    polkit.enable = true;
  };
}
