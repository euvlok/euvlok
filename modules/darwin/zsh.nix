{
  pkgs,
  lib,
  config,
  ...
}:
let
  hmConfig = config.home-manager.users.${config.system.primary.user};

  omzPlugins = [
    "colorize"
    "dotnet"
    "podman"
  ]
  ++ lib.lists.filter (name: hmConfig.programs.${name}.enable) [
    "direnv"
    "fzf"
    "git"
    "ssh"
    "vscode"
  ];

  plugins = [
    {
      name = "history-substring-search";
      src = pkgs.zsh-history-substring-search;
      file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
    }
    {
      name = "nix-shell";
      src = pkgs.zsh-nix-shell;
      file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
    }
  ]
  ++ lib.lists.optional hmConfig.programs.fzf.enable {
    name = "fzf-tab";
    src = pkgs.zsh-fzf-tab;
    file = "share/fzf-tab/fzf-tab.plugin.zsh";
  };
in
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    fast.syntax.highlighting.enable = true;
    autocd = true;
    shell.aliases = hmConfig.programs.zsh.shellAliases;
    oh.my.zsh = {
      enable = true;
      plugins = omzPlugins;
    };
    inherit plugins;

    init.content = lib.modules.mkMerge [
      (lib.modules.mkOrder 500 (
        lib.strings.concatStringsSep "\n" [
          "# Home Manager session environment"
          ". ${hmConfig.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"

          (lib.strings.optionalString hmConfig.sshAuthSock.enable ''
            # ndw owns shell startup instead of Home Manager
            if [ -z "$SSH_AUTH_SOCK" ] || [ -z "$SSH_CONNECTION" ]; then
              ${hmConfig.sshAuthSock.initialization.zsh}
            fi
          '')
        ]
      ))
      (lib.modules.mkOrder 1500 (
        lib.strings.concatStringsSep "\n" [
          (lib.strings.optionalString hmConfig.programs.ghostty.enable ''
            if [[ -r "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration ]]; then
              source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
            fi
          '')
          (lib.strings.optionalString hmConfig.programs.starship.enable ''
            if [[ $TERM != "dumb" ]]; then
              eval "$(starship init zsh)"
            fi
          '')
          (lib.strings.optionalString hmConfig.euvlok.home.yazi.enable ''
            function yy() {
              local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
              yazi "$@" --cwd-file="$tmp"
                if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
              builtin cd -- "$cwd"
              fi
              rm -f -- "$tmp"
            }
          '')
          (lib.strings.optionalString hmConfig.programs.zoxide.enable ''eval "$(zoxide init zsh)"'')
          (lib.strings.optionalString
            (hmConfig.programs.zellij.enable && hmConfig.programs.zellij.enableZshIntegration)
            ''
              # ndw owns Zsh startup, so run Home Manager's Zellij integration
              # here, after loading its session environment
              if [[ "$USER" == ${lib.strings.escapeShellArg config.system.primary.user} && "$TERM" != "dumb" ]]; then
                eval "$(${lib.meta.getExe hmConfig.programs.zellij.finalPackage} setup --generate-auto-start zsh)"
              fi
            ''
          )
        ]
      ))
    ];
  };
}
