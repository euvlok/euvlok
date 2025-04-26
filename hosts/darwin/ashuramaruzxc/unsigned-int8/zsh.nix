{ pkgs, config, ... }:
{
  programs.zsh =
    (pkgs.callPackage ../../shared/zsh.nix {
      inherit config;
      hmConfig = config.home-manager.users.ashuramaru;
    }).programs.zsh;
}
