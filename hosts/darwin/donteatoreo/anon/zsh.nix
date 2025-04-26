{ pkgs, config, ... }:
{
  programs.zsh =
    (pkgs.callPackage ../../shared/zsh.nix {
      inherit config;
      hmConfig = config.home-manager.users.anon;
      extraAliases = ''alias "micfix"="sudo killall coreaudiod"'';
    }).programs.zsh;
}
