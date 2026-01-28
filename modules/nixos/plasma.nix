{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixos.plasma.enable = lib.mkEnableOption "KDE Plasma";

  config = lib.mkIf config.nixos.plasma.enable {
    services = {
      xserver.enable = true;
      displayManager.gdm.enable = true; # im sorry but sddm is brokenware
      displayManager.defaultSession = "plasma";
      desktopManager.plasma6.enable = true;
      gnome.gnome-settings-daemon.enable = true;
      dbus.packages = builtins.attrValues { inherit (pkgs) gcr; };
      udev.packages = builtins.attrValues {
        inherit (pkgs) gnome-settings-daemon;
        inherit (pkgs.gnome2) GConf;
      };
      gvfs.enable = true;
    };

    environment = {
      systemPackages =
        builtins.attrValues {
          inherit (pkgs)
            adwaita-icon-theme
            adwaita-qt
            adwaita-qt6
            dconf-editor # if not declaratively
            ;
          inherit (pkgs.unstable)
            darkly
            darkly-qt5
            ;
          inherit (pkgs.kdePackages)
            ark
            filelight
            kclock
            konsole
            merkuro # Calendar

            dolphin
            dolphin-plugins
            kio
            kio-admin
            kio-extras
            kio-extras-kf5
            kio-fuse
            kio-gdrive
            kio-zeroconf

            # Formats
            kdegraphics-thumbnailers # Thumbnails
            kdesdk-thumbnailers # Thumbnailers
            kimageformats # Gimp
            qtimageformats # Webp
            qtsvg # Svg

            discover
            flatpak-kcm
            kcmutils
            packagekit-qt

            # Accounts
            accounts-qt
            kaccounts-integration
            kaccounts-providers
            signond

            # Mail
            akonadi
            akonadi-calendar
            akonadi-contacts
            akonadi-search
            calendarsupport
            kcontacts
            kmail
            kmail-account-wizard
            kmailtransport
            knotifications
            korganizer
            kservice
            ;
        }
        ++ lib.optionalAttrs config.catppuccin.enable builtins.attrValues {
          catppuccin-gtk = pkgs.catppuccin-gtk.override {
            accents = [ config.catppuccin.accent ];
            size = "compact";
            tweaks = [ "rimless" ];
            variant = config.catppuccin.flavor;
          };
          catppuccin-kde = pkgs.catppuccin-kde.override {
            accents = [ config.catppuccin.accent ];
            flavour = [ config.catppuccin.flavor ];
            winDecStyles = [ "classic" ];
          };
        };
    };
  };
}
