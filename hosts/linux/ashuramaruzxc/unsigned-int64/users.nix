{
  pkgs,
  config,
  ...
}:
{
  programs.zsh.enable = true;
  users.mutableUsers = false;
  users.groups = {
    ashuramaru.gid = config.users.users.ashuramaru.uid;
    minecraft = {
      gid = config.users.users.minecraft.uid;
      members = [
        "ashuramaru"
        "minecraft"
        "nginx"
      ];
    };
    nginx.members = [ "minecraft" ];
    password = {
      gid = config.users.users.password.uid;
      members = [
        "ashuramaru"
        "nextcloud"
      ];
    };
  };
  users.users = {
    password = {
      isSystemUser = true;
      group = "password";
      extraGroups = [ "ashuramaru" ];
    };
    nginx.extraGroups = [ "minecraft" ];
    root = {
      initialHashedPassword = "";
      openssh.authorizedKeys.keys = config.users.users.ashuramaru.openssh.authorizedKeys.keys ++ [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSS01C9Um/08HZJH8CCTdUvkJK8RUmZ4QD91V5KAFfd faputa@faputas-Mac-mini.local"
      ];
      shell = pkgs.zsh;
    };
    ashuramaru = {
      isNormalUser = true;
      uid = 1000;
      home = "/Users/ashuramaru";
      description = "Mariè Levjéwa";
      initialHashedPassword = "";
      extraGroups = [
        "ashuramaru"
        "wheel"
        "docker"
        "minecraft"
      ];
      openssh.authorizedKeys.keys = import ../../../keys/ashuramaru.nix;
      shell = pkgs.zsh;
    };
  };
}
