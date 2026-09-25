{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.modules.mkIf config.programs.zsh.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "euvlok Zsh" pkgs lib.platforms.linux)
    ];
    programs.zsh = {
      autosuggestion.enable = true;
      fastSyntaxHighlighting.enable = true;
      autocd = true;
      historySubstringSearch.enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "colorize"
          "dotnet"
          "gitfast"
          "podman"
          "ssh"
          "vscode"
        ];
      };
      plugins = [
        {
          name = "nix-shell";
          src = pkgs.zsh-nix-shell;
        }
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
      ];
    };
  };
}
