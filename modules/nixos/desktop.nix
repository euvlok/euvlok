{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.euvlok.nixos.gui.enable {
    qt = {
      enable = true;
      platformTheme = lib.mkDefault "qt5ct";
    };

    programs.ssh.askPassword = lib.mkForce (
      if config.euvlok.nixos.plasma.enable then
        lib.meta.getExe pkgs.unstable.kdePackages.ksshaskpass
      else
        lib.meta.getExe pkgs.unstable.seahorse
    );
  };
}
