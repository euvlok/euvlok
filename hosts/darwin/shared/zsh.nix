{
  pkgs,
  lib,
  config,
  hmConfig,
  extraAliases ? "",
  extraInteractiveInit ? "",
  ...
}:
let
  shellAliases =
    ((pkgs.callPackage ../../../modules/hm/shell/aliases.nix { osConfig = config; })
      .programs.zsh.shellAliases
    )
    // lib.optionalAttrs (hmConfig.home.username == "anon") (
      (pkgs.callPackage ../../hm/donteatoreo/aliases.nix { }).programs.zsh.shellAliases
    );
  shellAliasesStr =
    builtins.attrNames shellAliases
    |> builtins.filter (an: builtins.isString shellAliases.${an})
    |> map (an: "alias ${an}=${lib.escapeShellArg shellAliases.${an}}")
    |> builtins.concatStringsSep "\n";

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
  customPluginsStr = customPlugins |> lib.concatMapStringsSep "\n" (p: "source ${p.src}");
  omzPluginsStr = "plugins=(${lib.concatStringsSep " " omzPlugins})";

  interactiveShellInit = lib.concatStringsSep "\n" [
    "# Oh My Zsh"
    omzPluginsStr
    "source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh"

    "# Aliases"
    shellAliasesStr
    extraAliases

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
in
{
  programs.zsh = { inherit promptInit interactiveShellInit; };
}
