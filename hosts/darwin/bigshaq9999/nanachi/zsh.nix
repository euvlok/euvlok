{ pkgs, config, ... }:
let
  hmConfig = config.home-manager.users.faputa;
in
{
  programs.zsh =
    (pkgs.callPackage ../../shared/zsh.nix {
      inherit config hmConfig;
    }).programs.zsh;
  launchd.user.agents."symlink-zsh-config" = {
    script = ''
      ln -sfn "/etc/zprofile" "${hmConfig.home.homeDirectory}/.zprofile"
      ln -sfn "/etc/zshenv" "${hmConfig.home.homeDirectory}/.zshenv"
      ln -sfn "/etc/zshrc" "${hmConfig.home.homeDirectory}/.zshrc"
    '';
    serviceConfig.RunAtLoad = true;
    serviceConfig.StartInterval = 0;
  };
}
