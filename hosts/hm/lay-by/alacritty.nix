{ lib, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 5;
          y = 5;
        };
      };
      terminal = {
        shell = "fish";
      };
      font = {
        size = lib.modules.mkForce 10;
      };
    };
  };
}
