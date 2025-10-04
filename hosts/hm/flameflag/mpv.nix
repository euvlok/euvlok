_: {
  programs.mpv.bindings = {
    # Playback Control
    "SPACE" = "cycle pause";
    "MBTN_LEFT" = "cycle pause";
    "f" = "cycle fullscreen";
    "Z-Q" = "quit";
    "L" = "ab_loop"; # Set A-B loop points
    "o" = "cycle osc; cycle osd-bar"; # Toggle on-screen controller and OSD bar

    "UP" = "add volume 2";
    "DOWN" = "add volume -2";
    "m" = "cycle mute";

    # Seeking
    "LEFT" = "seek -5";
    "RIGHT" = "seek 5";
    "Shift+LEFT" = "seek -60";
    "Shift+RIGHT" = "seek +60";
    "," = "frame-back-step";
    "." = "frame-step";

    "v" = "cycle sub"; # Toggle subtitles
    "s" = "cycle sub"; # Switch subtitle tracks

    "a" = "cycle audio"; # Switch audio tracks

    # Playback Speed Control
    "[" = "add speed -0.1";
    "]" = "add speed 0.1";
    "BS" = "set speed 1";
  };
  programs.mpv.config = {
    volume = 50; # Default volume level
    volume-max = 120; # Maximum volume level
    sub-font-size = 36;
    sub-color = "#FFFFFF";
  };
}
