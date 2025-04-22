_: {
  programs.niri.settings = {
    environment.DISPLAY = ":0";
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/Screenshot_%Y%m%d_%H%M%S.png";
    window-rules = [
      {
        # Credit: https://github.com/linuxmobile/kaku/blob/3273c7ac6c172410f5ce29b7ea38ba3be940b212/home/software/wayland/niri/rules.nix#L42-L51
        geometry-corner-radius =
          let
            radius = 16.0;
          in
          {
            bottom-left = radius;
            bottom-right = radius;
            top-left = radius;
            top-right = radius;
          };
        clip-to-geometry = true;
      }
    ];
  };
}
