{
  perSystem =
    {
      config,
      inputs,
      pkgs,
      system,
      ...
    }:
    let
      lib = pkgs.lib;
      unstable = import inputs.nixpkgs-unstable-small {
        inherit system;
        config.allowUnfree = true;
      };
      kanata =
        let
          version = "1.12.0-prerelease-2";
          src = pkgs.fetchFromGitHub {
            owner = "FlameFlag";
            repo = "kanata";
            rev = "c8c720ded5a34bbc4bdfbfbe33c97b7bb2e60e77";
            hash = "sha256-xnmoRf+xKRSlKPKnCRYsid4laL5+eCD1IP09RjuyjXY=";
          };
        in
        pkgs.kanata.overrideAttrs (old: {
          inherit version src;

          cargoCheckFeatures =
            (old.cargoCheckFeatures or [ ])
            ++ lib.lists.optionals pkgs.stdenv.hostPlatform.isLinux [
              "simulated_output"
            ];

          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit src;
            name = "kanata-flameflag-2026-06-05";
            hash = "sha256-dVQhiEj8izA4lv4lZdLHr6rND8Gm8pvAx6mP6MPK1zk=";
          };
        });
      ghidraMcpHeadless = pkgs.callPackage ../packages/ghidra-mcp-headless.nix {
        inherit (unstable)
          ghidra
          jdk21
          maven
          python313
          ;
      };

      mkRustPackage =
        {
          name,
          cratePath ? "packages/${name}",
          mainProgram ? name,
          nativeCheckInputs ? [ ],
          preCheck ? "",
          wrapInputs ? [ ],
        }:
        let
          crateRoot = ../. + "/${cratePath}";
          crateManifest = lib.trivial.importTOML (crateRoot + "/Cargo.toml");
          workspaceManifest = lib.trivial.importTOML ../Cargo.toml;
          repository =
            let
              crateRepository = crateManifest.package.repository or null;
            in
            if builtins.isString crateRepository then
              crateRepository
            else
              workspaceManifest.workspace.package.repository;
        in
        pkgs.rustPlatform.buildRustPackage (finalAttrs: {
          pname = crateManifest.package.name;
          version = crateManifest.package.version;
          src = lib.fileset.toSource {
            root = ../.;
            fileset = lib.fileset.unions [
              ../Cargo.toml
              ../Cargo.lock
              ../bootstrap
              ../crates
              (../. + "/dotfiles/flameflag/dot_config/nushell/completions/chezmoi-support.nu")
              (../. + "/dotfiles/flameflag/Library/Application Support/nushell/completions/chezmoi-support.nu")
              ../hosts/hm/lay-by/hyprland/scripts
              ../packages
              crateRoot
            ];
          };
          cargoLock = {
            lockFile = ../Cargo.lock;
          };
          cargoBuildFlags = [
            "--package"
            finalAttrs.pname
          ];
          cargoTestFlags = [
            "--package"
            finalAttrs.pname
          ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          inherit nativeCheckInputs preCheck;
          postInstall = lib.strings.optionalString (wrapInputs != [ ]) ''
            wrapProgram "$out/bin/${mainProgram}" \
              --prefix PATH : ${lib.strings.makeBinPath wrapInputs}
          '';
          meta = {
            inherit mainProgram;
            description = crateManifest.package.description or "Rust utility for the euvlok dotfiles";
            homepage = repository;
            license = lib.licenses.mit;
            platforms = lib.platforms.unix;
          };
        });
    in
    {
      packages = {
        auto-rebase = mkRustPackage {
          name = "auto-rebase";
          nativeCheckInputs = [
            pkgs.git
            pkgs.jujutsu
          ];
          preCheck = ''
            export GIT_AUTHOR_NAME=auto-rebase
            export GIT_AUTHOR_EMAIL=auto-rebase@localhost
            export GIT_COMMITTER_NAME=auto-rebase
            export GIT_COMMITTER_EMAIL=auto-rebase@localhost
          '';
          wrapInputs = [
            pkgs.git
            pkgs.jujutsu
          ];
        };
        bootstrap = mkRustPackage {
          name = "bootstrap-cli";
          cratePath = "crates/bootstrap-cli";
          mainProgram = "bootstrap";
        };
        browser-extension-update = mkRustPackage {
          name = "browser-extensions-update";
          mainProgram = "browser-extension-update";
          wrapInputs = [ pkgs.git ];
        };
        catppuccin-userstyles = mkRustPackage {
          name = "catppuccin-userstyles";
          mainProgram = "build-catppuccin-userstyles";
        };
        chezmoi-support = mkRustPackage {
          name = "chezmoi-support";
          cratePath = "crates/chezmoi-support";
        };
        github-maintenance = mkRustPackage { name = "github-maintenance"; };
        http-fixture = mkRustPackage { name = "http-fixture"; };
        nvidia-prefetch = mkRustPackage { name = "nvidia-prefetch"; };
        zellij-theme-tools = mkRustPackage {
          name = "zellij-theme-tools";
          mainProgram = "zellij-auto-theme";
        };

        inherit kanata;
        kanata-with-cmd = kanata.override { withCmd = true; };
        lldb-mcp-launcher = pkgs.callPackage ../packages/lldb-mcp-launcher.nix {
          lldb = unstable.llvmPackages_22.lldb;
          python3 = unstable.python3;
        };

        ghidra-mcp-headless-bridge = ghidraMcpHeadless.bridge;
        ghidra-mcp-headless-httpd = ghidraMcpHeadless.httpd;
        ghidra-mcp-headless-server = ghidraMcpHeadless.server;
      };

      overlayAttrs = {
        inherit (config.packages)
          auto-rebase
          bootstrap
          browser-extension-update
          catppuccin-userstyles
          chezmoi-support
          github-maintenance
          http-fixture
          nvidia-prefetch
          zellij-theme-tools
          ;
      };

      apps = lib.attrsets.mapAttrs (_: pkg: {
        type = "app";
        program = lib.meta.getExe pkg;
      }) config.packages;
    };
}
