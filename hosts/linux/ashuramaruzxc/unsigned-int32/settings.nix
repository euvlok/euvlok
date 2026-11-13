{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /etc/.Trash-${toString config.users.users.ashuramaru.uid} 0700 ashuramaru users -"
  ];

  services = {
    fstrim.enable = true;
    fstrim.interval = "weekly";
    gvfs.enable = true;
  };
  nix.settings.trusted-users = [
    "@wheel"
    "ashuramaru"
  ];
}
