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
      lldb-mcp-launcher = final.callPackage ../../packages/lldb-mcp-launcher.nix {
        lldb = final.unstable.llvmPackages_22.lldb;
        python3 = final.unstable.python3;
      };
      ghidra-mcp-headless = final.callPackage ../../packages/ghidra-mcp-headless.nix {
        inherit (final.unstable)
          ghidra
          jdk21
          maven
          python313
          ;
      };
      kanata =
        let
          version = "1.12.0-prerelease-2";
          src = final.fetchFromGitHub {
            owner = "FlameFlag";
            repo = "kanata";
            rev = "c8c720ded5a34bbc4bdfbfbe33c97b7bb2e60e77";
            hash = "sha256-xnmoRf+xKRSlKPKnCRYsid4laL5+eCD1IP09RjuyjXY=";
          };
        in
        _prev.kanata.overrideAttrs (old: {
          inherit version src;

          cargoCheckFeatures =
            (old.cargoCheckFeatures or [ ])
            ++ final.lib.lists.optionals final.stdenv.hostPlatform.isLinux [
              "simulated_output"
            ];

          cargoDeps = final.rustPlatform.fetchCargoVendor {
            inherit src;
            name = "kanata-flameflag-2026-06-05";
            hash = "sha256-dVQhiEj8izA4lv4lZdLHr6rND8Gm8pvAx6mP6MPK1zk=";
          };
        });
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
