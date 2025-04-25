{ pkgs, config, ... }:
{
  programs.zsh =
    (pkgs.callPackage ../../shared/zsh.nix {
      hmConfig = config.home-manager.users.ashuramaruzxc;
    }).programs.zsh;
}
