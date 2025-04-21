#! add this to shared since it's perfect one for steam
{ pkgs, lib, ... }:
{
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
              libgdiplus
              libkrb5
              libpng
              libpulseaudio
              libvorbis
              mangohud
              mesa-demos
              source-han-sans
              steamtinkerlaunch
              thcrap-steam-proton-wrapper
              vkBasalt
              vulkan-caps-viewer
              vulkan-extension-layer
              vulkan-headers
              vulkan-loader
              vulkan-tools
              vulkan-validation-layers
              wqy_zenhei
              yad
              zenity
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

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs) scummvm inotify-tools;
    inherit (pkgs) winetricks protonplus;
    inherit (pkgs.wineWowPackages) stagingFull;
  };

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
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = [
      "\${HOME}/.steam/root/compatibilitytools.d:${pkgs.proton-ge-bin}"
    ];
  };
}
