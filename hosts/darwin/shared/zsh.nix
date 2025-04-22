{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.zsh = {
    interactiveShellInit =
      ''
        source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      ''
      + (lib.optionalString (lib.any (pkg: pkg == pkgs.github-copilot-cli) (
        config.environment.systemPackages
      )) (''eval "$(github-copilot-cli alias -- "$0")"''));
  };
}
