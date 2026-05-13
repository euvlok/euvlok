{
  inputs,
  config,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.self.overlays.default
    inputs.niri-flake-trivial.overlays.niri
    inputs.nix4vscode-trivial.overlays.default
  ]
  ++ [
    (_: prev: {
      unstable = import inputs.nixpkgs-unstable-small {
        inherit (prev.stdenv.hostPlatform) system;
        inherit (config.nixpkgs) config;
        overlays = [
          (_: unstablePrev: {
            openldap = unstablePrev.openldap.overrideAttrs (_: {
              doCheck = false;
            });
          })
        ];
      };
    })
    (final: _prev: {
      eupkgs = final.unstable.extend inputs.eupkgs.overlays.default;
      kanata-with-cmd = final.kanata.override { withCmd = true; };
    })
    /**
      nixpkgs @507531
      nix @6065
      nix @15638
    */
    (_: prev: {
      direnv = prev.direnv.overrideAttrs (_: {
        doCheck = false;
      });
    })
  ];
}
