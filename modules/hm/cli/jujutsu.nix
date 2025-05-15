{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
{
  options.hm.jujutsu.enable = lib.mkEnableOption "Jujutsu";

  config = lib.mkIf config.hm.jujutsu.enable {
    home.packages = builtins.attrValues { inherit (pkgs) watchman; };
    programs.jujutsu = {
      enable = true;
      package = inputs.jj-vcs-source.packages.${osConfig.nixpkgs.hostPlatform.system}.default;
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
