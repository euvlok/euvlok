{ config, ... }:
{
  systemd.tmpfiles.settings.desktop."/etc/.Trash-${toString config.users.users.ashuramaru.uid}".d = {
    mode = "0700";
    user = "ashuramaru";
    group = "users";
  };

  services.gvfs.enable = true;
  nix.settings.trusted-users = [
    "@wheel"
    "ashuramaru"
  ];
}
