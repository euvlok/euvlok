{
  lib,
  config,
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
    };
  };
}
