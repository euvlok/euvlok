_: {
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
