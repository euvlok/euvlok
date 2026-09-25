{
  lib,
  pkgs,
  ...
}:
{
  programs.ssh = {
    enable = lib.modules.mkDefault true;
    package = pkgs.openssh_hpn;
    enableDefaultConfig = false;
    settings."*" = {
      AddKeysToAgent = "yes";
    };
  };
}
