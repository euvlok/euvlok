{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.hm.ssh.enable = lib.options.mkEnableOption "SSH" // {
    default = true;
  };

  config = lib.modules.mkIf config.hm.ssh.enable {
    programs.ssh = {
      enable = true;
      package = pkgs.openssh_hpn;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        addKeysToAgent = "yes";
      };
    };
  };
}
