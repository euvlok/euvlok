{ pkgs, ... }:
{
  programs.steam.extraCompatPackages = builtins.attrValues {
    inherit (pkgs.unstable) proton-ge-bin steamtinkerlaunch;
  };
  nixpkgs.overlays = [
    (_: super: {
      steam = super.unstable.steam.override {
        extraPkgs =
          steamSuper:
          builtins.attrValues {
            inherit (steamSuper)
              curl
              desktop-file-utils # for some native wrappers
              imagemagick
              keyutils
              mangohud
              mesa-demos
              nwjs # who knew that i would need that for rpg maker games
              source-han-sans
              steamtinkerlaunch # just in case compattools doesn't works
              vkbasalt
              vulkan-validation-layers
              wqy_zenhei
              yad
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
              vulkan-tools
              ;
            inherit (steamSuper.xorg)
              libXcursor
              libXi
              libXinerama
              libXScrnSaver
              xhost
              ;
            inherit (steamSuper.kdePackages) qtbase;
            inherit (steamSuper.stdenv.cc.cc) lib;
            inherit (steamSuper) thcrap-steam-proton-wrapper;
          };
      };
      bottles = super.bottles.override { removeWarningPopup = true; };
    })
  ];
}
