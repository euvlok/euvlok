{
  cursorName,
  cursorPackage,
  size ? 32,
  iconName ? "breeze-dark",
  iconPackage,
}:
{
  lib,
  config,
  osConfig,
  ...
}:
{
  home.pointerCursor = {
    enable = true;
    name = cursorName;
    package = cursorPackage;
    inherit size;
    gtk.enable = true;
    x11 = {
      enable = true;
      defaultCursor = cursorName;
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = lib.modules.mkForce iconName;
      package = lib.modules.mkForce iconPackage;
    };
  };

  catppuccin.i-still-want-to-use-the-archived-gtk-theme-because-it-works-better-than-everything-else = {
    enable = true;
    inherit (osConfig.catppuccin) accent flavor;
    size = "standard";
    tweaks = [
      "rimless"
      "normal"
    ];
  };

  home.sessionVariables = {
    GTK_CSD = "0";
    GO_PATH = "${config.home.homeDirectory}/.go";
    GEM_HOME = "${config.home.homeDirectory}/.gems";
    GEM_PATH = "${config.home.homeDirectory}/.gems";
  };

  services.easyeffects.enable = true;
}
