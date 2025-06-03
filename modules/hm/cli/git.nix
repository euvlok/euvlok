{
  pkgs,
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
        git = {
          enable = true;
          package = pkgs.gitMinimal; # We don't use SVN; we also don't need GUI, manual, Python support, or PCRE2
          ignores = [
            "*.DS_Store"
            "*.swp"
            ".DS_Store"
            "Thumbs.db"
            "result"
            "result*"
          ];
          aliases = {
            grep = "!sh -c 'rg --vimgrep --color=always --line-number --no-heading --smart-case \"$@\"' _";
          };
        };
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
