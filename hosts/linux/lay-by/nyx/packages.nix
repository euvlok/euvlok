{ zenBrowserPackage }:
{ lib, pkgs, ... }:
{
  environment.systemPackages = lib.attrsets.attrValues {
    inherit (pkgs)
      brightnessctl
      wget
      git
      libsecret
      ffmpeg
      hyprpolkitagent
      wayland-protocols
      wayland-utils
      wl-clipboard
      wlroots
      xdg-utils
      meson
      gcc
      glibc
      jq
      cachix
      bc
      ninja
      wireshark
      gpu-screen-recorder
      gpu-screen-recorder-gtk
      seahorse
      ;
    inherit (pkgs.unstable.kdePackages)
      breeze
      breeze-gtk
      breeze-icons
      ;
    zen-browser = zenBrowserPackage;
  };
}
