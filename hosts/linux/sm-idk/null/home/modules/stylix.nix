{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.stylix.homeModules.stylix ];

  stylix = {
    enable = true;
    polarity = "dark";
    # polarity = "light";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/vesper.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/borland.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-dark.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/default-dark.yaml";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/black-metal.yaml";

    cursor = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    # iconTheme = {
    #   enable = true;
    #   dark = "MoreWaita";
    #   package = pkgs.morewaita-icon-theme;
    # };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };

    overlays.enable = false;

    targets = {
      #   gtk.extraCss = ''
      #     @define-color sidebar_bg_color #${config.lib.stylix.colors.base00};
      #     @define-color headerbar_bg_color #${config.lib.stylix.colors.base00};
      #   '';
      zed.enable = false;
      nixcord.enable = false;
    };
  };
}
