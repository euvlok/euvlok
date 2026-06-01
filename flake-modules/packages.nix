{
  perSystem =
    { config, pkgs, ... }:
    let
      lib = pkgs.lib;

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
        nvidia-prefetch = mkRustPackage { name = "nvidia-prefetch"; };
        zellij-theme-tools = mkRustPackage {
          name = "zellij-theme-tools";
          mainProgram = "zellij-auto-theme";
        };
      };

      overlayAttrs = {
        inherit (config.packages)
          auto-rebase
          bootstrap
          browser-extension-update
          catppuccin-userstyles
          chezmoi-support
          github-maintenance
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
