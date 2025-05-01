{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixos.plasma.enable = lib.mkEnableOption "KDE Plasma";

  config = lib.mkIf config.nixos.plasma.enable {
    services = {
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
            adw-gtk3
            catppuccin-kde
            ;
          inherit (inputs.lightly.packages.${config.nixpkgs.hostPlatform.system})
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

            flatpak-kcm
            kcmutils
            ;
        }
        ++ lib.optionalAttrs config.catppuccin.enable builtins.attrValues {
          catppuccin-gtk = pkgs.catppuccin-gtk.override {
            accents = [ config.catppuccin.accent ];
            size = "compact";
            tweaks = [ "normal" ];
            variant = config.catppuccin.flavor;
          };
        };
    };
  };
}
