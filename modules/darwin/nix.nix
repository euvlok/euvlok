_: {

  # ndw owns the existing Determinate installation and writes shared settings
  # to /etc/nix/nix.custom.conf
  determinateNix = {
    enable = true;
    determinateNixd.garbageCollector.strategy = "automatic";
  };
}
