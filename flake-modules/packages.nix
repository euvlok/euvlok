{
  perSystem =
    { config, pkgs, ... }:
    let
      mkBunPackage =
        {
          name,
          dir ? name,
        }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [
            pkgs.bun
            pkgs.git
          ];
          text = ''
            cd "$(git rev-parse --show-toplevel)"
            exec bun --bun run ./packages/${dir}/src/index.ts -- "$@"
          '';
        };
    in
    {
      packages = {
        auto-rebase = mkBunPackage { name = "auto-rebase"; };
        browser-extension-update = mkBunPackage {
          name = "browser-extension-update";
          dir = "browser-extensions-update";
        };
        nvidia-prefetch = mkBunPackage { name = "nvidia-prefetch"; };
      };

      apps = pkgs.lib.mapAttrs (_: pkg: {
        type = "app";
        program = pkgs.lib.getExe pkg;
      }) config.packages;
    };
}
