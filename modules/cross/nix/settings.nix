{ isDarwin }:
_:
let
  settings = {
    # Determinate owns its performance defaults (including eval-cores and
    # lazy-trees). Keep only deliberate overrides in nix.custom.conf.
    warn-dirty = false;

    # Preserve Determinate Nix's managed caches. nix.custom.conf is included
    # from its generated nix.conf, so bare list settings would replace the
    # managed values instead of extending them.
    #
    # Let remote builders use the same binary caches as the coordinator.
    builders-use-substitutes = true;
    extra-substituters = [
      "https://catppuccin.cachix.org"
      "https://devenv.cachix.org"
      "https://euvlok.cachix.org"
      "https://eupkgs.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
      "https://cache.nixos-cuda.org"
      "https://cache.flox.dev"
    ];
    extra-trusted-public-keys = [
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "euvlok.cachix.org-1:cmFWCSs7rxPiyE1qfaJn8TY7QaRoGOrzKuNvtGw2gcU="
      "eupkgs.cachix.org-1:V9Y0HdASNNSU9U6EkXhR1j85bZGRtNgW7wSyTiQrwGU="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };
in
{

  config =
    if isDarwin then
      {
        # The Determinate nix-darwin module disables nix-darwin's Nix config
        # writer. Put all custom settings in its supported include instead.
        determinateNix.customSettings = settings;
      }
    else
      {
        nix.settings = settings // {
          # Do not mix the global registry with the locked per-host registry.
          flake-registry = "";
        };

        # Channels are imperative state; flake inputs are the source of truth.
        nix.channel.enable = false;
      };
}
