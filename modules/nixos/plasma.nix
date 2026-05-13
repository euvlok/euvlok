{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  mkCatppuccinGtk =
    {
      tweaks ? [ ],
    }:
    pkgs.unstable.catppuccin-gtk.override {
      accents = [ config.catppuccin.accent ];
      variant = config.catppuccin.flavor;
      size = "compact";
      inherit tweaks;
    };
in
{
  #! temp remove plasma from nixos-unstable
  # disabledModules = [ "services/desktop-managers/plasma6.nix" ];

  # imports = [
  #   ("${inputs.nixpkgs-unstable-small.outPath}/nixos/modules/services/desktop-managers/plasma6.nix")
  # ];

  options.nixos.plasma.enable = lib.mkEnableOption "KDE Plasma";

  config = lib.mkIf config.nixos.plasma.enable {
    nixos.gui.enable = lib.mkDefault true;

    nixpkgs.overlays = [
      (_final: prev: {
        kdePackages = prev.unstable.kdePackages;
      })
    ];
    services = {
      displayManager.plasma-login-manager.enable = true;
      displayManager.defaultSession = "plasma";
      desktopManager.plasma6.enable = true;
    };

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
          Environment = [ "QSG_RHI_BACKEND=opengl" ];
          UnsetEnvironment = [
            "EGL_PLATFORM"
            "QT_QPA_PLATFORM"
          ];
        };
      };
      plasma-wallpaper = {
        overrideStrategy = "asDropin";
        serviceConfig = {
          Environment = [ "QSG_RHI_BACKEND=opengl" ];
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
            ;
          inherit (pkgs.unstable.kdePackages)
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
        ++ lib.optionals config.catppuccin.enable [
          (mkCatppuccinGtk { tweaks = [ "rimless" ]; })
          (pkgs.unstable.catppuccin-kde.override {
            accents = [ config.catppuccin.accent ];
            flavour = [ config.catppuccin.flavor ];
            winDecStyles = [ "classic" ];
          })
        ];
    };
  };
}
