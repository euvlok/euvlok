{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.android-development;
in
{
  options.programs.android-development = {
    enable = lib.options.mkEnableOption "Android development tools";
    waydroid.enable = lib.options.mkEnableOption "Waydroid support";
  };

  config = lib.modules.mkIf cfg.enable {
    virtualisation.waydroid.enable = cfg.waydroid.enable;
    environment.systemPackages = builtins.attrValues {
      inherit (pkgs) android-tools scrcpy;
    };
  };
}
