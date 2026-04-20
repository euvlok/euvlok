{
  perSystem =
    { config, pkgs, ... }:
    {
      formatter = pkgs.nixfmt;

      pre-commit.settings = {
        excludes = [
          ".direnv"
          ".devenv"
        ];
        hooks = {
          nixfmt-rfc-style = {
            enable = true;
            package = pkgs.nixfmt;
          };
          shellcheck.enable = true;
        };
      };

      devenv.shells.default = {
        name = "euvlok development shell";
        languages = {
          nix.enable = true;
          shell.enable = true;
        };
        enterShell = config.pre-commit.installationScript;
        packages = builtins.attrValues {
          inherit (pkgs) git pre-commit bun;
          inherit (pkgs) nix-index nix-prefetch-github nix-prefetch-scripts;
        };
      };
    };
}
