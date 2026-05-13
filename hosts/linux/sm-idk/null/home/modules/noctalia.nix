{
  inputs,
  pkgs,
  config,
  ...
}:
let
  noctalia =
    cmd:
    [
      "noctalia-shell"
      "ipc"
      "call"
    ]
    ++ (pkgs.lib.splitString " " cmd);
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  home.packages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    # inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  programs = {
    noctalia-shell = {
      enable = true;
      settings = {
        settingsVersion = 15;
        bar = {
          widgets = {
            left = [ { id = "Workspace"; } ];
            center = [ { id = "Clock"; } ];
            right = [
              { id = "MediaMini"; }
              { id = "Tray"; }
              { id = "NotificationHistory"; }
              { id = "Volume"; }
              { id = "Brightness"; }
              { id = "Battery"; }
              { id = "SystemMonitor"; }
              { id = "ControlCenter"; }
            ];
          };
        };
        location = {
          name = "Warsaw";
        };
        wallpaper = {
          randomEnabled = false;
          overviewEnabled = false;
          directory = "/home/bruno/Pictures/Wallpapers";
        };
        colorSchemes = {
          # predefinedScheme = "Rosepine";
          # predefinedScheme = "Ayu";
          predefinedScheme = "Rosey AMOLED";
          generateTemplatesForPredefined = false;
        };
        dock.enabled = false;
        overviewEnabled = true;
      };
    };
    niri.settings.binds = with config.lib.niri.actions; {
      "Mod+L".action.spawn = noctalia "lockScreen lock";
      XF86MonBrightnessUp = {
        action.spawn = noctalia "brightness increase";
        allow-when-locked = true;
      };
      XF86MonBrightnessDown = {
        action.spawn = noctalia "brightness decrease";
        allow-when-locked = true;
      };
    };
  };
}
