{
  config,
  lib,
  pkgs,
  ...
}:
let
  hyprctl = lib.meta.getExe' config.programs.hyprland.package "hyprctl";
  notifySend = lib.meta.getExe pkgs.libnotify;
  scxLoaderPackage = config.services.scx-loader.package or pkgs.scx.loader;
  scxctl = lib.meta.getExe' scxLoaderPackage "scxctl";

  /**
    Build a GameMode lifecycle hook that toggles Waybar GPU polling, switches
    `scx_lavd`'s mode, adjusts Hyprland visual effects, and sends a notification

    # Inputs

    `options` (attribute set)

    : `name` (required)
      : Derivation and executable name for the hook script

      `scxMode` (required)
      : Target `scxctl switch --mode` profile (for example `"gaming"` or `"auto"`)

      `hyprEffects` (required)
      : Hyprland keyword value (`"0"` or `"1"`) applied to blur and animations

      `notification` (required)
      : Desktop notification text sent via `notify-send`

      `setFlag` (required)
      : Whether to create (`true`) or remove (`false`) the GameMode flag file

    # Type

    ```
    mkGamemodeHook :: {
      name :: String;
      scxMode :: String;
      hyprEffects :: String;
      notification :: String;
      setFlag :: Bool;
    } -> Derivation
    ```

    # Examples
    :::{.example}
    ## Build a GameMode start hook

    ```nix
    (mkGamemodeHook {
      name = "gamemode-start";
      scxMode = "gaming";
      hyprEffects = "0";
      notification = "GameMode started";
      setFlag = true;
    }).name
    => "gamemode-start"
    ```

    :::
  */
  mkGamemodeHook =
    {
      name,
      scxMode,
      hyprEffects,
      notification,
      setFlag,
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        flag_file="$runtime_dir/gamemode-active"
        ${if setFlag then ''touch "$flag_file"'' else ''rm -f "$flag_file"''}

        ${scxctl} switch --mode ${lib.strings.escapeShellArg scxMode} >/dev/null 2>&1 || true

        hypr_sig="''${HYPRLAND_INSTANCE_SIGNATURE:-}"
        if [ -z "$hypr_sig" ] && [ -d "$runtime_dir/hypr" ]; then
          for sock in "$runtime_dir/hypr"/*/.socket.sock; do
            if [ -S "$sock" ]; then
              hypr_sig="$(basename "$(dirname "$sock")")"
              break
            fi
          done
        fi
        if [ -n "$hypr_sig" ]; then
          HYPRLAND_INSTANCE_SIGNATURE="$hypr_sig" ${hyprctl} --batch \
            "keyword decoration:blur:enabled ${hyprEffects}; keyword animations:enabled ${hyprEffects}" \
            >/dev/null 2>&1 || true
        fi

        ${notifySend} ${lib.strings.escapeShellArg notification} || true
      '';
    };

  gamemodeStart = mkGamemodeHook {
    name = "gamemode-start";
    scxMode = "gaming";
    hyprEffects = "0";
    notification = "GameMode started";
    setFlag = true;
  };

  gamemodeEnd = mkGamemodeHook {
    name = "gamemode-end";
    scxMode = "auto";
    hyprEffects = "1";
    notification = "GameMode ended";
    setFlag = false;
  };

  gameRun = pkgs.writeShellApplication {
    name = "game-run";
    runtimeInputs = [
      config.systemd.package
      pkgs.gamemode
    ];
    text = ''
      exec systemd-run --user --scope --slice=gaming.slice -- gamemoderun "$@"
    '';
  };
in
{
  imports = [ ../shared/programs.nix ];

  environment.systemPackages = [ gameRun ];

  programs = {
    steam = {
      enable = true;
      extest.enable = lib.modules.mkForce false;
    };
    gamemode.settings = {
      general = {
        renice = 10;
        ioprio = 0;
        inhibit_screensaver = 1;
      };
      custom = {
        start = lib.modules.mkForce (lib.meta.getExe gamemodeStart);
        end = lib.modules.mkForce (lib.meta.getExe gamemodeEnd);
      };
    };
  };
}
