{ lib, ... }:
{
  programs.bash = {
    enable = lib.modules.mkDefault true;
    enableVteIntegration = true;
  };
}
