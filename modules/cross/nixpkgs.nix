{
  inputs,
  config,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    inputs.niri-flake-trivial.overlays.niri
    inputs.nix4vscode-trivial.overlays.default
  ]
  ++ [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable-small {
        inherit (prev.stdenv.hostPlatform) system;
        inherit (config.nixpkgs) config;
      };
    })
    (final: prev: {
      eupkgs = inputs.eupkgs.legacyPackages.${prev.stdenv.hostPlatform.system};
    })
  ];
}
