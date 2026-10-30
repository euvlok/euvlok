_: {

  # Let Determinate own nix.conf and nix-daemon instead of having nix-darwin
  # generate a competing installation. Custom Nix settings are routed to
  # /etc/nix/nix.custom.conf by the shared modules.
  determinateNix = {
    enable = true;
    determinateNixd.garbageCollector.strategy = "automatic";
  };
}
