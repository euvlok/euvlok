{
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
  tesseractLang = [
    "pol" # Polish
    "deu" # German
    "eng" # English
    "fra" # French
    "rus" # Russian
    "ukr" # Ukrainian
    "jpn" # Japanese
    "jpn_vert" # Japanese, vertical text
    "chi_sim" # Chinese, simplified
    "chi_sim_vert" # Chinese, simplified vertical text
    "chi_tra" # Chinese, traditional
    "chi_tra_vert" # Chinese, traditional vertical text
    "osd" # Orientation and script detection
    "kor" # Korean
    "kor_vert" # Korean, vertical text
    "spa" # Spanish
    "ita" # Italian
    "nld" # Dutch
    "ces" # Czech
    "slk" # Slovak
    "por" # Portuguese
    "tur" # Turkish
    "aze" # Azerbaijani, Latin script
    "aze_cyrl" # Azerbaijani, Cyrillic script
    "yid" # Yiddish
    "heb" # Hebrew
    "ara" # Arabic
    "fas" # Persian/Farsi
  ];
in
{
  #! temp remove plasma from nixos-unstable
  # disabledModules = [ "services/desktop-managers/plasma6.nix" ];

  # imports = [
  #   ("${inputs.nixpkgs-unstable-small.outPath}/nixos/modules/services/desktop-managers/plasma6.nix")
  # ];

  options.nixos.plasma.enable = lib.options.mkEnableOption "KDE Plasma";

  config = lib.modules.mkIf config.nixos.plasma.enable {
    nixos.gui.enable = lib.modules.mkDefault true;

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
            tesseract # spectacle just in case
            ;
          # screenshot OCR
          spectacle = pkgs.kdePackages.spectacle.override { tesseractLanguages = tesseractLang; };
          skanpage = pkgs.kdePackages.skanpage.override { tesseractLanguages = tesseractLang; };
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
