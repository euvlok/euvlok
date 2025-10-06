{
  inputs,
  config,
  ...
}:
{
  _module.args.pkgsUnstable = import inputs.nixpkgs-unstable-small {
    inherit (config.nixpkgs.hostPlatform) system;
    inherit (config.nixpkgs) config;
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    inputs.nur-trivial.overlays.default
    inputs.nix-vscode-extensions-trivial.overlays.default
    inputs.rust-overlay-source.overlays.default
    (final: prev: {
      yt-dlp = final.callPackage ../../pkgs/yt-dlp.nix { };
      yt-dlp-script = final.callPackage ../../pkgs/yt-dlp-script.nix { };
      warp-terminal-catppuccin = final.callPackage ../../pkgs/warp-terminal-catppuccin.nix {
        inherit (config.catppuccin) accent;
      };
    })
  ];
}
