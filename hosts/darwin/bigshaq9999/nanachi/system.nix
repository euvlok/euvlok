{ lib, ... }:
{
  system = {
    keyboard.enableKeyMapping = true;
    defaults.dock = {
      tilesize = 44;
    };
    stateVersion = 5;
  };
}
