{
  perSystem =
    { config, pkgs, ... }:
    let
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
          ] ++ pkgs.lib.optionals (name == "auto-rebase") [
            pkgs.jujutsu
          ];
          text = ''
            cd "$(git rev-parse --show-toplevel)"
            exec bun --bun run ${script} -- "$@"
          '';
        };
    in
    {
      packages = {
        auto-rebase = mkBunPackage { name = "auto-rebase"; };
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

      apps = pkgs.lib.mapAttrs (_: pkg: {
        type = "app";
        program = pkgs.lib.getExe pkg;
      }) config.packages;
    };
}
