{
  pkgs,
  lib,
  config,
  ...
}:
let
  hmConfig = config.home-manager.users.${config.system.primaryUser};

  # Home Manager has already merged the shared and user-specific aliases.
  # Consume that module result instead of reaching back into hosts/ by name.
  shellAliases = hmConfig.programs.zsh.shellAliases;
  shellAliasesStr = lib.trivial.pipe shellAliases [
    (attrs: lib.attrsets.filterAttrs (_: value: builtins.isString value) attrs)
    (
      filteredAttrs:
      lib.generators.toKeyValue {
        mkKeyValue = name: value: "alias ${name}=${lib.strings.escapeShellArg value}";
      } filteredAttrs
    )
  ];

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

  customPlugins = [
    {
      name = "nix-shell";
      src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh";
    }
  ]
  ++ lib.lists.optional hmConfig.euvlok.home.fzf.enable {
    name = "fzf-tab";
    src = "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh";
  };
  customPluginsStr = lib.strings.concatMapStringsSep "\n" (
    plugin: "source ${plugin.src}"
  ) customPlugins;

  omzPluginsStr = "plugins=(${lib.strings.concatStringsSep " " omzPlugins})";
in
{
  programs.zsh = {
    enableAutosuggestions = true;
    enableFastSyntaxHighlighting = true;

    interactiveShellInit = lib.strings.concatStringsSep "\n" [
      "# Home Manager session environment"
      ". ${hmConfig.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"

      "# Oh My Zsh"
      omzPluginsStr
      "source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh"

      "# Aliases"
      shellAliasesStr

      "setopt autocd"

      "# History substring search"
      "source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"

      "# Custom plugins"
      customPluginsStr
    ];

    promptInit = lib.strings.concatStrings [
      (lib.strings.optionalString hmConfig.euvlok.home.ghostty.enable ''
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
      (lib.strings.optionalString hmConfig.euvlok.home.zoxide.enable ''eval "$(zoxide init zsh)"'')
    ];
  };

  home-manager.users.${config.system.primaryUser} =
    { config, lib, ... }:
    {
      home.file =
        lib.attrsets.genAttrs
          [
            ".zprofile"
            ".zshenv"
            ".zshrc"
          ]
          (name: {
            force = true;
            source = config.lib.file.mkOutOfStoreSymlink "/etc/${lib.strings.removePrefix "." name}";
          });
    };
}
