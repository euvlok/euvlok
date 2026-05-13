{
  perSystem =
    { config, pkgs, ... }:
    let
      lib = pkgs.lib;

      mkRustPackage =
        {
          name,
        }:
        let
          crateRoot = ../packages + "/${name}";
          crateManifest = lib.importTOML (crateRoot + "/Cargo.toml");
        in
        pkgs.rustPlatform.buildRustPackage (finalAttrs: {
          pname = crateManifest.package.name;
          version = crateManifest.package.version;
          src = lib.fileset.toSource {
            root = ../.;
            fileset = lib.fileset.unions [
              ../Cargo.toml
              ../Cargo.lock
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
          postInstall = ''
            wrapProgram "$out/bin/${name}" \
              --prefix PATH : ${
                lib.makeBinPath [
                  pkgs.git
                  pkgs.jujutsu
                ]
              }
          '';
          meta = {
            mainProgram = finalAttrs.pname;
            description = crateManifest.package.description;
            homepage = crateManifest.package.repository;
            license = lib.licenses.mit;
            platforms = lib.platforms.unix;
          };
        });

      mkBunPackage =
        {
          name,
          script ? name,
        }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [
            pkgs.bun
            pkgs.git
          ];
          text = ''
            cd "$(git rev-parse --show-toplevel)"
            exec bun --bun run ${script} -- "$@"
          '';
        };
    in
    {
      packages = {
        auto-rebase = mkRustPackage { name = "auto-rebase"; };
        browser-extension-update = mkBunPackage {
          name = "browser-extension-update";
        };
        nvidia-prefetch = mkBunPackage { name = "nvidia-prefetch"; };
      };

      overlayAttrs = {
        inherit (config.packages)
          auto-rebase
          browser-extension-update
          nvidia-prefetch
          ;
      };

      apps = lib.mapAttrs (_: pkg: {
        type = "app";
        program = lib.getExe pkg;
      }) config.packages;
    };
}
