{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.modules.mkIf config.euvlok.nixos.gui.enable {
    qt = {
      enable = true;
      platformTheme = lib.modules.mkDefault "qt5ct";
    };

    programs.ssh.askPassword = lib.modules.mkForce (
      if config.euvlok.nixos.plasma.enable then
        lib.meta.getExe pkgs.unstable.kdePackages.ksshaskpass
      else
        lib.meta.getExe pkgs.unstable.seahorse
    );
  };
}
