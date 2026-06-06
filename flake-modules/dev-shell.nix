{
  perSystem =
    { config, pkgs, ... }:
    {
      treefmt.programs.nixfmt.enable = true;

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
        devenv.root = toString ./..;
        languages = {
          nix.enable = true;
          shell.enable = true;
        };
        enterShell = config.pre-commit.installationScript;
        packages = builtins.attrValues {
          inherit (pkgs)
            git
            pre-commit
            jujutsu
            ;
          inherit (pkgs) nix-index nix-prefetch-github nix-prefetch-scripts;
          inherit (config.packages)
            browser-extension-update
            catppuccin-userstyles
            github-maintenance
            ;
        };
      };
    };
}
