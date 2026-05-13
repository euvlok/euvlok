{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      keepassxc
      ;
  };

  programs.keepassxc.settings = {
    General.MinimizeAfterUnlock = true;
    Browser.Enabled = true;
    GUI = {
      ApplicationTheme = "dark";
      ColorPasswords = true;
      MinimizeToTray = true;
      ShowTrayIcon = true;
      TrayIconAppearance = "monochrome-light";
    };
    SecretServiceIntegration.Enabled = true;
  };
}
