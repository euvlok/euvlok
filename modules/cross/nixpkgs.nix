{
  inputs,
  config,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable-small {
        inherit (prev.stdenv.hostPlatform) system;
        config = config.nixpkgs.config;
      };
    })
    inputs.niri-flake-trivial.overlays.niri
    inputs.nix4vscode-trivial.overlays.default
    (final: prev: {
      yt-dlp = final.callPackage ../../pkgs/yt-dlp.nix { };
      yt-dlp-script = final.callPackage ../../pkgs/yt-dlp-script.nix { };
      warp-terminal-catppuccin = final.callPackage ../../pkgs/warp-terminal-catppuccin.nix {
        inherit (config.catppuccin) accent;
      };
    })
  ];
}
