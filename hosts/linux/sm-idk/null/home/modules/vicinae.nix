{ pkgs, ... }:
{
  programs.vicinae = {
    enable = true;
    systemd.autoStart = true;
    package = pkgs.vicinae;

    settings = {
      faviconService = "twenty";
      font.size = 11;
      popToRootOnClose = false;
      rootSearch.searchFiles = false;
      # theme.name = "vicinae-dark";
      window = {
        # csd = true;
        # opacity = 0.85;
        rounding = 10;
      };
    };
  };
}
