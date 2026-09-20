{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.euvlok.nixos.gui.enable =
    lib.options.mkEnableOption "graphical session (display server + common GUI daemons)";

  config = lib.modules.mkIf config.euvlok.nixos.gui.enable {
    services = {
      xserver.enable = true;
      libinput.enable = true;
      gvfs.enable = true;
      gnome.gnome-keyring.enable = true;
      gnome.gnome-settings-daemon.enable = true;
      dbus.packages = [ (pkgs.gcr_3 or pkgs.gcr) ];
      udev.packages = builtins.attrValues { inherit (pkgs.unstable) gnome-settings-daemon; };
    };
  };
}
