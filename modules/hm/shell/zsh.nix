{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
{
  options.hm.zsh.enable = lib.mkEnableOption "Declerative Zsh";

  config = lib.mkIf config.hm.zsh.enable {
    assertions = [
      {
        assertion = osConfig.nixpkgs.hostPlatform.isLinux;
        message = "Declerative Zsh is only available on Linux";
      }
    ];
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting = {
        enable = true;
        highlighters = [
          "main"
          "brackets"
        ];
      };
      autocd = true;
      historySubstringSearch.enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "colorize"
          "direnv"
          "dotnet"
          "fzf"
          "gitfast"
          "podman"
          "ssh"
          "vscode"
        ];
      };
      plugins = [
        {
          name = "fast-syntax-highlighting";
          src = pkgs.zsh-fast-syntax-highlighting;
        }
        # {
        #   name = "fzf-tab";
        #   src = pkgs.zsh-fzf-tab;
        # }
        {
          name = "nix-shell";
          src = pkgs.zsh-nix-shell;
        }
      ];
      initContent = ''
        source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
      '';
    };
  };
}
