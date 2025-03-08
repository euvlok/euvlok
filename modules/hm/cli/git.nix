{
  lib,
  config,
  osConfig,
  release,
  ...
}:

{
  options.hm.git.enable = lib.mkEnableOption "Git";

  config = lib.mkIf config.hm.git.enable {
    home.file.".gitconfig".source = lib.mkIf (osConfig.nixpkgs.hostPlatform.isDarwin) (
      config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/.gitconfig"
    );
    programs =
      {
        gitui.enable = true;
        gh.enable = true;
        git.enable = true;
        git.ignores = [
          ".DS_Store"
          "Thumbs.db"
          "*.DS_Store"
          "*.swp"
          "result"
          "result*"
        ];
      }
      // lib.optionalAttrs (release < 25) {
        vscode.userSettings =
          lib.optionalAttrs
            (release < 25 && lib.attrByPath [ "programs" "git" "signing" "signByDefault" ] null config != null)
            {
              "git.enableCommitSigning" = lib.attrByPath [
                "programs"
                "git"
                "signing"
                "signByDefault"
              ] null config;
            };
      }
      // lib.optionalAttrs (release > 25) {
        vscode.profiles.default.userSettings =
          lib.optionalAttrs
            (release < 25 && lib.attrByPath [ "programs" "git" "signing" "signByDefault" ] null config != null)
            {
              "git.enableCommitSigning" = lib.attrByPath [
                "programs"
                "git"
                "signing"
                "signByDefault"
              ] null config;
            };
      };
  };
}
