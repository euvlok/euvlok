{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixos.steam.enable = lib.mkEnableOption "Steam";

  config = lib.mkIf config.nixos.steam.enable {
    nixpkgs.overlays = [
      (_: super: {
        steam = super.steam.override {
          extraPkgs =
            super:
            builtins.attrValues {
              inherit (super)
                curl
                glxinfo
                imagemagick
                keyutils
                mangohud
                mesa-demos
                source-han-sans
                steamtinkerlaunch
                thcrap-steam-proton-wrapper
                vkBasalt
                vulkan-validation-layers
                wqy_zenhei
                yad
                zenity
                ;
              inherit (pkgs)
                libgdiplus
                libkrb5
                libpng
                libpulseaudio
                libvorbis
                ;
              inherit (pkgs)
                vulkan-caps-viewer
                vulkan-extension-layer
                vulkan-headers
                vulkan-loader
                vulkan-tools
                ;
              inherit (super.xorg)
                libXcursor
                libXi
                libXinerama
                libXScrnSaver
                xhost
                ;
              inherit (super.stdenv.cc.cc) lib;
            };
        };
      })
    ];

    programs = {
      steam = {
        enable = true;
        protontricks.enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = builtins.attrValues { inherit (pkgs) proton-ge-bin; };
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
      systemPackages = builtins.attrValues {
        inherit (pkgs) scummvm inotify-tools;
        inherit (pkgs) winetricks protonplus;
        inherit (pkgs.wineWowPackages) stagingFull;
      };
      sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = [
        "\${HOME}/.steam/root/compatibilitytools.d:${pkgs.proton-ge-bin}"
      ];
    };
  };
}
