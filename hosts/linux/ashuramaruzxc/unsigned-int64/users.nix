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
    fumono.gid = config.users.users.fumono.uid;
    minecraft = {
      gid = config.users.users.minecraft.uid;
      members = [
        "ashuramaru"
        "fumono"
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
      openssh.authorizedKeys.keys = config.users.users.ashuramaru.openssh.authorizedKeys.keys;
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
        "podman"
        "minecraft"
      ];
      openssh.authorizedKeys.keys = import ../../../keys/ashuramaru.nix;
      shell = pkgs.zsh;
    };
    fumono = {
      isNormalUser = true;
      home = "/Users/fumono";
      description = "Fumono";
      initialHashedPassword = "";
      extraGroups = [
        "fumono"
        "docker"
        "podman"
        "minecraft"
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAHBeBj6thLiVFNGZI1NuTHKIPvh332Szad2zsgjdzhR mc-server"
      ];
      shell = pkgs.zsh;
    };
  };
}
