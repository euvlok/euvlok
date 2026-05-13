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

      mkZigPackage =
        {
          name,
        }:
        let
          packageRoot = ../packages + "/${name}";
        in
        pkgs.stdenv.mkDerivation {
          pname = name;
          version = "0-unstable";
          src = lib.fileset.toSource {
            root = packageRoot;
            fileset = packageRoot;
          };

          nativeBuildInputs = [ pkgs.zig_0_16 ];

          doCheck = true;
          checkPhase = ''
            runHook preCheck
            zig build test
            runHook postCheck
          '';

          installPhase = ''
            runHook preInstall
            zig build install -Doptimize=ReleaseSafe --prefix "$out"
            runHook postInstall
          '';

          meta = {
            description = "Fetch NVIDIA driver hashes and update the Nix expression";
            license = lib.licenses.mit;
            mainProgram = name;
            platforms = lib.platforms.unix;
          };
        };

      mkZiglintPackage =
        let
          version = "0.5.2";
          sources = {
            aarch64-darwin = {
              artifact = "ziglint-aarch64-macos.tar.gz";
              hash = "sha256-7F7Wk4p+iFGdiTtwd6c3O3dRWeTnCNYxSHtZ8FWyM1Y=";
            };
            aarch64-linux = {
              artifact = "ziglint-aarch64-linux.tar.gz";
              hash = "sha256-Dtjzaah/lji/0OETdGrXkiUu2gaoKsa8P1hIeGQhw0A=";
            };
            x86_64-linux = {
              artifact = "ziglint-x86_64-linux.tar.gz";
              hash = "sha256-XqxsF1/0iDCg4Nl4SpY8wvNfLVOkZSEsyVNSXo9d9rs=";
            };
          };
          source = sources.${pkgs.stdenvNoCC.hostPlatform.system};
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "ziglint";
          inherit version;
          src = pkgs.fetchurl {
            url = "https://github.com/rockorager/ziglint/releases/download/v${version}/${source.artifact}";
            inherit (source) hash;
          };
          sourceRoot = ".";
          dontBuild = true;
          dontFixup = true;
          installPhase = ''
            runHook preInstall

            install -D -m755 ziglint $out/bin/ziglint

            runHook postInstall
          '';
          meta = {
            description = "Static analysis for Zig";
            homepage = "https://github.com/rockorager/ziglint";
            license = lib.licenses.mit;
            mainProgram = "ziglint";
            platforms = builtins.attrNames sources;
          };
        };
    in
    {
      packages = {
        auto-rebase = mkRustPackage { name = "auto-rebase"; };
        browser-extension-update = mkBunPackage {
          name = "browser-extension-update";
        };
        nvidia-prefetch = mkZigPackage { name = "nvidia-prefetch"; };
        ziglint = mkZiglintPackage;
      };

      overlayAttrs = {
        inherit (config.packages)
          auto-rebase
          browser-extension-update
          nvidia-prefetch
          ziglint
          ;
      };

      apps = lib.mapAttrs (_: pkg: {
        type = "app";
        program = lib.getExe pkg;
      }) config.packages;
    };
}
