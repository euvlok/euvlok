{ zenBrowserPackage }:
{ lib, pkgs, ... }:
{
  environment.localBinInPath = true;
  environment.systemPackages = lib.attrsets.attrValues {
    inherit (pkgs)
      # Base System
      wget
      git
      libsecret
      ffmpeg
      hyprpolkitagent
      usbutils
      net-tools
      desktop-file-utils
      unzip
      p7zip
      file
      font-manager
      killall
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

      # Android device control
      android-tools
      scrcpy

      # QEMU
      #qemu
      #quickemu
      #virt-manager

      # Security
      wireshark

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
    ghidra = pkgs.ghidra.withExtensions (exts: [
      (
        if exts.reva.version == "7.3.1" then
          exts.reva.overrideAttrs (old: {
            # Ghidra 12.2's storeFile now throws IOException; propagate it to the factory.
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/main/java/reva/revaFileSystem.java \
                --replace-fail 'public void mount(TaskMonitor monitor) {' \
                'public void mount(TaskMonitor monitor) throws IOException {'
            '';
          })
        else
          exts.reva
      )
    ]);
    zen-browser = zenBrowserPackage;
  };
}
