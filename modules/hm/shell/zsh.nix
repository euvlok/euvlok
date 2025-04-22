{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
{
  options.hm.zsh = {
    enable = lib.mkEnableOption "Declerative Zsh";
    ohMyZsh = lib.mkEnableOption "Oh My Zsh";
    basicQoL = lib.mkEnableOption "Basic QoL Settings";
    extraQoL = lib.mkEnableOption "Extra QoL Settings";
  };

  config = lib.mkIf config.hm.zsh.enable {
    assertions = [
      {
        assertion = osConfig.nixpkgs.hostPlatform.isLinux;
        message = "Declerative Zsh is only available on Linux";
      }
    ];
    programs.zsh = {
      enable = true;
      autosuggestion.enable = if config.hm.zsh.basicQoL then true else false;
      syntaxHighlighting = lib.optionalAttrs config.hm.zsh.basicQoL {
        enable = true;
        highlighters = [ "brackets" ];
      };
      autocd = if config.hm.zsh.basicQoL then true else false;
      historySubstringSearch.enable = true;
      plugins = lib.optionals config.hm.zsh.extraQoL [
        {
          name = "fast-syntax-highlighting";
          src = pkgs.zsh-fast-syntax-highlighting;
        }
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
        }
        {
          name = "nix-shell";
          src = pkgs.zsh-nix-shell;
        }
      ];
      oh-my-zsh = lib.optionalAttrs config.hm.zsh.ohMyZsh {
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
    };
  };
}
