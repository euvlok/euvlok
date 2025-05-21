{
  lib,
  config,
  osConfig,
  ...
}:

{
  options.hm.git.enable = lib.mkEnableOption "Git";

  config = lib.mkMerge [
    (lib.mkIf config.hm.git.enable {
      programs = {
        gitui.enable = true;
        gh.enable = true;
        git.enable = true;
        git.ignores = [
          "*.DS_Store"
          "*.swp"
          ".DS_Store"
          "Thumbs.db"
          "result"
          "result*"
        ];
        vscode.profiles.default.userSettings = {
          git.enableCommitSigning = if (config.programs.git.signing.key != null) then true else false;
        };
      };
    })
    (lib.mkIf (osConfig.nixpkgs.hostPlatform.isDarwin) {
      home.file.".gitconfig".source =
        config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/.gitconfig";
    })
  ];
}
