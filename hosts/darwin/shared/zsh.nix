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

  omzPlugins = [
    "colorize"
    "direnv"
    "dotnet"
    "fzf"
    "gitfast"
    "podman"
    "ssh"
    "vscode"
  ];

  customPlugins = [
    {
      name = "fast-syntax-highlighting";
      src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
    }
    {
      name = "fzf-tab";
      src = "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh";
    }
    {
      name = "nix-shell";
      src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh";
    }
  ];

  customPluginsStr = customPlugins |> lib.concatMapStringsSep "\n" (p: "source ${p.src}");
  omzPluginsStr = "plugins=(${lib.concatStringsSep " " omzPlugins})";

  interactiveShellInit = lib.concatStringsSep "\n" [
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
    "# Oh My Zsh"
    omzPluginsStr
    "source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh"
    extraInteractiveInit
  ];

  promptInit = lib.mkMerge [
    ''''
    (lib.optionalString (hmConfig.programs.starship.enable) (''
      if [[ $TERM != "dumb" ]]; then
        eval "$(starship init zsh)"
      fi
    ''))
    (lib.optionalString (hmConfig.programs.zellij.enable) (
      lib.mkOrder 200 ''eval "$(zellij setup --generate-auto-start zsh)"''
    ))
    (lib.optionalString (hmConfig.programs.zoxide.enable) (
      lib.mkOrder 2000 ''eval "$(zoxide init zsh)"''
    ))
  ];
in
{
  system.activationScripts.postActivation.text = ''
    ln -sfn "/etc/zshrc" "${hmConfig.home.homeDirectory}/.zshrc"
    ln -sfn "/etc/zshenv" "${hmConfig.home.homeDirectory}/.zshenv"
    ln -sfn "/etc/zprofile" "${hmConfig.home.homeDirectory}/.zprofile"
  '';

  programs.zsh = { inherit promptInit interactiveShellInit; };
}
