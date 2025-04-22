{ lib, pkgs, ... }:
{
  nixpkgs.config.packageOverrides.steam = pkgs.steam.override {
    extraPkgs = lib.attrValues {
      inherit (pkgs.xorg)
        libXcursor
        libXi
        libXinerama
        libXScrnSaver
        ;

      inherit (pkgs)
        libkrb5
        libpng
        libpulseaudio
        libvorbis
        gtk3
        gtk3-x11
        keyutils
        libgdiplus
        mono
        zlib
        ;

      inherit (pkgs.stdenv.cc.cc) lib;
    };
  };
}
