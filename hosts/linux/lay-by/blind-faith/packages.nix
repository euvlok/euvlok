{ zenBrowserPackage }:
{ pkgs, ... }:
{
  environment.localBinInPath = true;
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      # Base System
      wget
      git
      libsecret
      ffmpeg
      hyprpolkitagent

      # Desktop
      wayland-protocols
      wayland-utils
      wl-clipboard
      wlroots
      xdg-utils

      # Development
      meson
      gcc
      glibc
      jq
      cachix
      bc
      ninja
      uv

      # QEMU
      #qemu
      #quickemu
      #virt-manager

      # Security
      wireshark
      ghidra

      # Recording
      gpu-screen-recorder
      gpu-screen-recorder-gtk

      ;
    # Theme stuff
    inherit (pkgs.unstable.kdePackages)
      breeze
      breeze-gtk
      breeze-icons
      ;
    inherit (pkgs) seahorse;
    zen-browser = zenBrowserPackage;
  };
}
