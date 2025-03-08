{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.hm.ssh.enable = lib.mkEnableOption "SSH";

  config = lib.mkIf config.hm.ssh.enable {
    programs.ssh = {
      enable = true;
      package = pkgs.openssh_hpn;
      addKeysToAgent = "yes";
    };
  };
}
