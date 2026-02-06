{
  lib,
  pkgs,
  config,
  ...
}:
{
  programs.rofi = {
    enable = true;
    package = pkgs.unstable.rofi;
    extraConfig = {
      modi = "drun,run,filebrowser,ssh,window";
      show-icons = true;
      display-drun = " Apps";
      display-run = " Run";
      display-filebrowser = " Files";
      display-window = " Windows";
      display-ssh = " SSH";
      drun-display-format = "{name}";
      window-format = "{w} · {c} · {t}";
    };

    theme = ./rofi.rasi;
  };
  home.file.".local/share/rofi/themes/colors.rasi".text = ''
    * {
    background:     #${config.lib.stylix.colors.base00};
    background-alt: #${config.lib.stylix.colors.base01};
    foreground:     #${config.lib.stylix.colors.base05};
    selected:       #${config.lib.stylix.colors.base0B};
    active:         #${config.lib.stylix.colors.base0C};
    urgent:         #${config.lib.stylix.colors.base08};
    font:           "${config.stylix.fonts.monospace.name}";
    }
  '';
}
