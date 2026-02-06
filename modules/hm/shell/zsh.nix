{
  pkgs,
  lib,
  config,
  ...
}:
let
  paths = import ./paths.nix { inherit lib; };
in
{
  options.hm.zsh.enable =
    lib.mkEnableOption "Declerative Zsh"
    // lib.optionalAttrs (pkgs.stdenvNoCC.isLinux) {
      default = true;
    };

  config = lib.mkIf config.hm.zsh.enable {
    assertions = [
      {
        message = "You cannot use Home-Manager Zsh on Darwin";
        assertion = pkgs.stdenvNoCC.isLinux;
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
        {
          name = "nix-shell";
          src = pkgs.zsh-nix-shell;
        }
      ];
      initContent = ''
        ${paths.hm.shell.binPaths.zsh}
        source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
      '';
    };
  };
}
