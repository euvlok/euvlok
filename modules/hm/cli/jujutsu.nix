{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.euvlok.home.jujutsu.enable = lib.options.mkEnableOption "Jujutsu";

  config = lib.modules.mkIf config.euvlok.home.jujutsu.enable {
    home.packages = builtins.attrValues { inherit (pkgs.stable) watchman; };
    programs.jujutsu = {
      enable = true;
      settings = {
        core.fsmonitor = "watchman";
        core.watchman.register-snapshot-trigger = true;
        ui = {
          paginate = "auto";
          merge-editor = "vscode";
          diff.format = "git";
        };
        git = {
          auto-local-bookmark = false;
          subprocess = true;
        };
      };
    };
  };
}
