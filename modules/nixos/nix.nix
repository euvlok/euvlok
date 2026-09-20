_: {

  # Determinate's module redirects the NixOS-generated configuration to the
  # supported /etc/nix/nix.custom.conf include.
  determinate.enable = true;

  nix = {
    # Determinate Nix 3.21 makes store optimisation multi-threaded. Running it
    # periodically avoids imposing the cost on every build.
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "70%";
    MemoryMax = "85%";
    MemorySwapMax = "50%";
  };
}
