{
  lib,
  config,
  pkgs,
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
      openssh.authorizedKeys.keys = lib.flatten [
        config.users.users.ashuramaru.openssh.authorizedKeys.keys
      ];
      shell = pkgs.zsh;
    };
    ashuramaru = {
      isNormalUser = true;
      uid = 1000;
      home = "/Users/ashuramaru";
      description = "Marie";
      initialHashedPassword = "";
      extraGroups = [
        "ashuramaru"
        "wheel"
        "docker"
        "podman"
        "minecraft"
      ];
      openssh.authorizedKeys.keys = [
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBNR1p1OviZgAkv5xQ10NTLOusPT8pQUG2qCTpO3AhmxaZM2mWNePVNqPnjxNHjWN+a/FcZ5on74QZQJtwXI5m80AAAAOc3NoOnJlbW90ZS1kc2E= email:ashuramaru@tenjin-dk.com id:ashuramaru@unsigned-int32"
        ### --- ecdsa-sk --- ###
        ### --- ecdsa-sk_bio --- ###
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBFdzdMIdu/bKlIkGx1tCf1sL65NwrmpvBZQ+nSbKknbGHdrXv33mMzLVUsCGUaUxmeYcCULNNtSb0kvgDjRlcgIAAAAOc3NoOnJlbW90ZS1kc2E= email:ashuramaru@tenjin-dk.com id:ashuramaru@unsigned-int32"
        ### --- ecdsa-sk_bio --- ###
        ### --- ed25519-sk --- ###
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKNF4qCh49NCn6DUnzOCJ3ixzLyhPCCcr6jtRfQdprQLAAAACnNzaDpyZW1vdGU= email:ashuramaru@tenjin-dk.com id:ashuramaru@unsigned-int32"
        ### --- ed25519-sk --- ###
        ### --- ed25519-sk_bio --- ###
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEF0v+eyeOEcrLwo3loXYt9JHeAEWt1oC2AHh+bZP9b0AAAACnNzaDpyZW1vdGU= email:ashuramaru@tenjin-dk.com id:ashuramaru@unsigned-int32"
        ### --- ed25519-sk_bio --- ###
      ];
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
    minecraft = {
      uid = 5333;
      isNormalUser = true;
      home = "/var/lib/minecraft";
      initialHashedPassword = "";
      extraGroups = [
        "minecraft"
        "ashuramaru"
        "fumono"
        "docker"
        "nginx"
      ];
      openssh.authorizedKeys.keys = lib.flatten [
        config.users.users.ashuramaru.openssh.authorizedKeys.keys
        config.users.users.fumono.openssh.authorizedKeys.keys
      ];
      shell = pkgs.zsh;
    };
  };
}
