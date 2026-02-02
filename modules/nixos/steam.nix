{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixos.steam.enable = lib.mkEnableOption "Steam";

  config = lib.mkIf config.nixos.steam.enable {
    hardware.steam-hardware.enable = true;
    # nixpkgs.overlays = [
    #   (_: super: {
    #     steam = super.unstable.steam.override {
    #       extraPkgs =
    #         steamSuper:
    #         (builtins.attrValues {
    #           inherit (steamSuper)
    #             curl
    #             mesa-demos
    #             imagemagick
    #             keyutils
    #             mangohud
    #             source-han-sans
    #             steamtinkerlaunch # just in case compattools doesn't works
    #             vkbasalt
    #             vulkan-validation-layers
    #             wqy_zenhei
    #             yad
    #             nwjs # who knew that i would need that for rpg maker games
    #             desktop-file-utils # for some native wrappers
    #             ;
    #           inherit (pkgs)
    #             libgdiplus
    #             libkrb5
    #             libpng
    #             libpulseaudio
    #             libvorbis
    #             ;
    #           inherit (pkgs)
    #             vulkan-caps-viewer
    #             vulkan-extension-layer
    #             vulkan-headers
    #             vulkan-tools
    #             ;
    #           inherit (steamSuper.xorg)
    #             libXcursor
    #             libXi
    #             libXinerama
    #             libXScrnSaver
    #             xhost
    #             ;
    #           inherit (steamSuper.kdePackages)
    #             qtbase
    #             ;
    #           inherit (steamSuper.stdenv.cc.cc) lib;
    #         })
    #         ++ (lib.optionals (config.users.users ? "ashuramaruzxc") (
    #           builtins.attrValues {
    #             inherit (steamSuper) thcrap-steam-proton-wrapper;
    #           }
    #         ));
    #     };
    #     # for people that want non official bottles
    #     bottles = super.bottles.override { removeWarningPopup = true; };
    #   })
    # ];

    programs = {
      steam = {
        enable = true;
        protontricks.enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };
      gamemode = {
        enable = true;
        enableRenice = true;
        settings.custom.start = "${lib.getExe pkgs.libnotify} 'GameMode started'";
        settings.custom.end = "${lib.getExe pkgs.libnotify} 'GameMode ended'";
      };
      gamescope.enable = true;
      gamescope.capSysNice = true;
    };

    environment = {
      systemPackages =
        (builtins.attrValues {
          inherit (pkgs) scummvm inotify-tools;
          inherit (pkgs) winetricks protonplus;
          inherit (pkgs.wineWowPackages) stagingFull;
        })
        ++ (lib.optionals config.services.desktopManager.gnome.enable (
          builtins.attrValues { inherit (pkgs) adwsteamgtk; }
        ));
    };
  };
}
