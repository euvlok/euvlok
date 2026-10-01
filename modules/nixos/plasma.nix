{
  lib,
  config,
  pkgs,
  ...
}:
let
  catppuccinGtk = pkgs.catppuccin-gtk-fausto.override {
    accent = config.catppuccin.accent;
    flavor = config.catppuccin.flavor;
    size = "compact";
    rimless = true;
  };
in
{

  imports = [ (import ../../slop.nix).nixos.plasma ];

  options.euvlok.nixos.plasma.enable = lib.options.mkEnableOption "KDE Plasma";

  config = lib.modules.mkIf config.euvlok.nixos.plasma.enable {
    euvlok.nixos.gui.enable = lib.modules.mkDefault true;

    nixpkgs.overlays = [
      (_: prev: {
        kdePackages = prev.unstable.kdePackages;
      })
    ];
    services = {
      displayManager.plasma-login-manager.enable = true;
      displayManager.defaultSession = "plasma";
      desktopManager.plasma6.enable = true;
    };

    # Temp fix for nvidia
    systemd.user.services = {
      plasma-login-kwin_wayland = {
        overrideStrategy = "asDropin";
        serviceConfig.UnsetEnvironment = [
          "EGL_PLATFORM"
          "QT_QPA_PLATFORM"
        ];
      };
      plasma-login = {
        overrideStrategy = "asDropin";
        serviceConfig = {
          Environment = [ "QSG_RHI_BACKEND=vulkan" ];
          UnsetEnvironment = [
            "EGL_PLATFORM"
            "QT_QPA_PLATFORM"
          ];
        };
      };
      plasma-wallpaper = {
        overrideStrategy = "asDropin";
        serviceConfig = {
          Environment = [ "QSG_RHI_BACKEND=vulkan" ];
          UnsetEnvironment = [
            "EGL_PLATFORM"
            "QT_QPA_PLATFORM"
          ];
        };
      };
    };

    environment = {
      systemPackages =
        builtins.attrValues {
          inherit (pkgs.unstable)
            adwaita-icon-theme
            adwaita-qt
            adwaita-qt6
            darkly
            dconf-editor # if not declaratively
            drawy
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

            # Misc
            kolourpaint
            okular
            ;
        }
        ++ lib.lists.optionals config.catppuccin.enable [
          catppuccinGtk
          (pkgs.unstable.catppuccin-kde.override {
            accents = [ config.catppuccin.accent ];
            flavour = [ config.catppuccin.flavor ];
            winDecStyles = [ "classic" ];
          })
        ];
    };
  };
}
