{ inputs, ... }:
{
  # Set `pkgs.unstable` arg
  # _module.args.pkgs.unstable = import inputs.nixpkgs-unstable {
  #   inherit (config.nixpkgs.hostPlatform) system;
  #   inherit (config.nixpkgs) config;
  # };

  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenvNoCC.hostPlatform) system;
        inherit (prev) config;
      };
    })
  ];

  # Nix settings
  nix = {
    optimise.automatic = true;
    channel.enable = false;

    settings = {
      experimental-features = "nix-command flakes";
      substituters = [ "https://nix-community.cachix.org/" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];

      extra-substituters = [
        "https://vicinae.cachix.org"

        "https://nixos-apple-silicon.cachix.org"
      ];
      extra-trusted-public-keys = [
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="

        "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      ];

      auto-optimise-store = true;
    };

    # Make builds run with low priority so system stays responsive
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  nixpkgs.config.allowUnfree = true;

  # Faster dbus implementation
  services.dbus.implementation = "broker";

  # Disable built-in NixOS documentation
  documentation.nixos.enable = false;

  programs.nh.enable = true;
}
