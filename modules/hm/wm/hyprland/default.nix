{ lib, config, ... }:
{
  options.euvlok.home.hyprland.enable = lib.options.mkEnableOption "Hyprland";

  config = lib.modules.mkIf config.euvlok.home.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      extraConfig = ''
        hl.config({
          ecosystem = { no_update_news = true },
          cursor = { no_hardware_cursors = 1 },
        })

        -- Audio control
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
        hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
        hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"))
        hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
        hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

        for workspace = 1, 10 do
          local key = workspace % 10
          hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
          hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
        end

        hl.window_rule({
          name = "shared-suppress-maximize",
          match = { class = ".*" },
          suppress_event = "maximize",
        })
        hl.window_rule({
          name = "shared-exe-immediate",
          match = { class = [[^.*\.exe$]] },
          immediate = true,
        })
      '';
    };
  };
}
