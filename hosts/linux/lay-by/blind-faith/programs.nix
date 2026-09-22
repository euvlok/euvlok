{ lib, ... }:
{
  imports = [ ../shared/programs.nix ];

  programs.steam = {
    enable = true;
    extest.enable = lib.modules.mkForce false;
  };
}
