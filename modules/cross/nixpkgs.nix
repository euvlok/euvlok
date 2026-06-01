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
      codex-lldb-mcp = final.callPackage ../../packages/codex-lldb-mcp.nix {
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
