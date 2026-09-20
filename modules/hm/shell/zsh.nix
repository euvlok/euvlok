{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.euvlok.home.zsh.enable = lib.options.mkEnableOption "declarative Zsh";

  config = lib.modules.mkIf config.euvlok.home.zsh.enable {
    assertions = [
      {
        message = "You cannot use Home-Manager Zsh on Darwin";
        assertion = pkgs.stdenvNoCC.hostPlatform.isLinux;
      }
    ];
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
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
          name = "nix-shell";
          src = pkgs.zsh-nix-shell;
        }
      ];
      initContent = ''
        source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
        source "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
      '';
    };
  };
}
