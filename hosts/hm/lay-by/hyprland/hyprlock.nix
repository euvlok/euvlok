_: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = false;
        immediate_render = true;
        # grace = 300;
        hide_cursor = true;
        no_fade_in = true;
      };

      background = [ { path = "~/Pictures/papes/starfighter2.png"; } ];

      input-field = [
        {
          size = "200, 50";
          position = "0, 0";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = "Password";
          shadow_passes = 2;
        }
      ];
    };
  };
}
