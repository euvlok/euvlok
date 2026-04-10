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
    inputs.claude-code.overlays.default
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
      claude-statusline =
        inputs.flameflag-dotfiles.packages.${prev.stdenv.hostPlatform.system}.claude-statusline;
    })
    /**
      nixpkgs @507531
      nix @6065
      nix @15638
    */
    (final: prev: {
      direnv = prev.direnv.overrideAttrs (_: {
        doCheck = false;
      });
    })
  ];
}
