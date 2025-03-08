{ config, lib, ... }:
let
  cfg = config.programs.android-development;
in
{
  options.programs.android-development = {
    enable = lib.mkEnableOption "Enable adb";
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc "List of users in adbusers group";
    };
    waydroid = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = lib.mdDoc "Enable waydroid support";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.adb.enable = true;
    users.groups.adbusers.members = lib.optionals cfg.enable cfg.users;
    virtualisation.waydroid.enable = lib.optionals cfg.enable cfg.waydroid.enable;
  };
}
