{ lib, ... }:
{
  system = {
    keyboard.enableKeyMapping = true;
    defaults.dock = {
      tilesize = 44;
      orientation = lib.mkForce "left";
      autohide = lib.mkForce false;
    };
    stateVersion = 5;
  };
}
