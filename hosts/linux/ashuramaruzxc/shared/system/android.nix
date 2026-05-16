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
    enable = lib.options.mkEnableOption "adb";
    users = lib.options.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of users in adbusers group";
    };
    waydroid = {
      enable = lib.options.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable waydroid support";
      };
    };
  };

  config = lib.modules.mkIf cfg.enable {
    users.groups.adbusers.members = lib.lists.optionals cfg.enable cfg.users;
    virtualisation.waydroid.enable = lib.lists.optionals cfg.enable cfg.waydroid.enable;
    environment.systemPackages = [
      pkgs.scrcpy
      pkgs.android-tools
    ];
  };
}
