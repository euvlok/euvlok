{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [ ../../shared ];

  system.activationScripts.postActivation.text = ''
    ln -sfn "/etc/zshrc" "${config.users.users.anon.home}/.zshrc"
    ln -sfn "/etc/zshenv" "${config.users.users.anon.home}/.zshenv"
    ln -sfn "/etc/zprofile" "${config.users.users.anon.home}/.zprofile"
  '';

  programs.zsh = {
    enableSyntaxHighlighting = true;
    promptInit = lib.optionalString (config.home-manager.users.anon.programs.starship.enable) (
      ''eval "$(starship init zsh)"''
    );
    interactiveShellInit =
      let
        shellAliases =
          ((pkgs.callPackage ../../../../modules/hm/shell/aliases.nix { osConfig = config; })
            .programs.zsh.shellAliases
          )
          // (pkgs.callPackage ../../../hm/donteatoreo/aliases.nix { }).programs.zsh.shellAliases;
        shellAliasesStr =
          builtins.attrNames shellAliases
          |> builtins.filter (an: builtins.isString shellAliases.${an})
          |> map (an: "alias ${an}=${lib.escapeShellArg shellAliases.${an}}")
          |> builtins.concatStringsSep "\n";
      in
      ''
        # Aliases
        ${shellAliasesStr}
        # macOS Specific Aliases
        alias "micfix"="sudo killall coreaudiod"
      ''
      + (lib.optionalString config.home-manager.users.anon.programs.zoxide.enable ''eval "$(zoxide init zsh)"'');
  };
}
