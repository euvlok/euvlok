{
  pkgs,
  lib,
  config,
  hmConfig ? config.home-manager.users.${config.system.primaryUser},
  extraInteractiveInit ? "",
  ...
}:
let
  userAliasesPath = ../../hm/${hmConfig.programs.git.userName}/aliases.nix;
  shellAliases =
    ((pkgs.callPackage ../../../modules/hm/shell/aliases.nix { osConfig = config; })
      .programs.zsh.shellAliases
    )
    // lib.optionalAttrs (builtins.pathExists userAliasesPath) (
      (pkgs.callPackage userAliasesPath { }).programs.zsh.shellAliases
    );
  shellAliasesStr = lib.pipe shellAliases [
    (attrs: lib.filterAttrs (name: value: builtins.isString value) attrs)
    (
      filteredAttrs:
      lib.mapAttrsToList (name: value: "alias ${name}=${lib.escapeShellArg value}") filteredAttrs
    )
    (builtins.concatStringsSep "\n")
  ];

  omzPlugins =
    let
      enablePlugin = n: lib.optionals hmConfig.programs.${n}.enable [ n ];
    in
    [
      "colorize"
      "dotnet"
      "podman"
    ]
    ++ enablePlugin "fzf"
    ++ enablePlugin "ssh"
    ++ enablePlugin "git"
    ++ enablePlugin "direnv"
    ++ enablePlugin "vscode";
  customPlugins =
    [
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
      }
      {
        name = "nix-shell";
        src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh";
      }
    ]
    ++ lib.optionals hmConfig.programs.fzf.enable [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
  customPluginsStr = lib.pipe customPlugins [
    (pluginsList: builtins.map (p: "source ${p.src}") pluginsList)
    (builtins.concatStringsSep "\n")
  ];
  omzPluginsStr = "plugins=(${lib.concatStringsSep " " omzPlugins})";

  interactiveShellInit = lib.concatStringsSep "\n" [
    "# Oh My Zsh"
    omzPluginsStr
    "source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh"

    "# Aliases"
    shellAliasesStr

    "# autocd"
    "setopt autocd"

    "# Autosuggestions"
    "source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

    "# Syntax highlighting"
    "ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)"
    "source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    "# History substring search"
    "source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"

    "# Custom plugins"
    customPluginsStr
    extraInteractiveInit
  ];
  promptInit = lib.mkMerge [
    (lib.optionalString (hmConfig.programs.ghostty.enable) (''
      if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
        source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
      fi
    ''))
    (lib.optionalString (hmConfig.programs.starship.enable) (''
      if [[ $TERM != "dumb" ]]; then
        eval "$(starship init zsh)"
      fi
    ''))
    (lib.optionalString (hmConfig.programs.yazi.enable) (''
      function yy() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
        yazi "$@" --cwd-file="$tmp"
          if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    ''))
    (lib.optionalString (hmConfig.programs.zoxide.enable) (''eval "$(zoxide init zsh)"''))
  ];

  launchd.user.agents."symlink-zsh-config" = {
    script = ''
      ln -sfn "/etc/zprofile" "/Users/${config.system.primaryUser}/.zprofile"
      ln -sfn "/etc/zshenv" "/Users/${config.system.primaryUser}/.zshenv"
      ln -sfn "/etc/zshrc" "/Users/${config.system.primaryUser}/.zshrc"
    '';
    serviceConfig.RunAtLoad = true;
    serviceConfig.StartInterval = 0;
  };
in
{
  programs.zsh = { inherit promptInit interactiveShellInit; };
}
