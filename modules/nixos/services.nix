{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixos.gui.enable = lib.mkEnableOption "graphical session (display server + common GUI daemons)";

  config = lib.mkIf config.nixos.gui.enable {
    services = {
      xserver.enable = true;
      libinput.enable = true;
      gvfs.enable = true;
      gnome.gnome-keyring.enable = true;
      gnome.gnome-settings-daemon.enable = true;
      dbus.packages = builtins.attrValues { inherit (pkgs.unstable) gcr; };
      udev.packages = builtins.attrValues {
        inherit (pkgs.unstable) gnome-settings-daemon;
        inherit (pkgs.unstable.gnome2) GConf;
      };
    };
  };
}
