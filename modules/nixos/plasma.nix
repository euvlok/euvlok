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
      gnome.gnome-settings-daemon.enable = true;
      dbus.packages = builtins.attrValues { inherit (pkgs) gcr; };
      udev.packages = builtins.attrValues {
        inherit (pkgs) gnome-settings-daemon;
        inherit (pkgs.gnome2) GConf;
      };
      gvfs.enable = true;
      xserver.displayManager.gdm.enable = true;
      displayManager.defaultSession = "plasma";
      desktopManager.plasma6.enable = true;
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
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
          inherit (inputs.lightly-source.packages.${config.nixpkgs.hostPlatform.system})
            darkly-qt5
            darkly-qt6
            ;
          inherit (pkgs.kdePackages)
            ark
            filelight
            kclock
            konsole # NOOOOO USE GHOSTTYYYY PLEAAAAASEEEEE
            merkuro # Calendar

            # for some reason not in by default
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
            kdegraphics-thumbnailers # blender etc
            kdesdk-thumbnailers # test
            kimageformats # gimp
            qtimageformats # webp etc
            qtsvg # svg

            discover
            flatpak-kcm
            kcmutils
            packagekit-qt

            # Somehwat working support accounts support
            accounts-qt
            kaccounts-integration
            kaccounts-providers
            signond

            # mail
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
