{
  inputs,
  pkgs,
  config,
  ...
}:
let
  addUnstablePackages = final: _: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system config;
    };
  };
in
{
  services.kmscon = {
    enable = true;
    extraOptions = "--term xterm-256color";
    extraConfig = "font-size=18";
    hwRender = true;
    fonts = [
      {
        name = "MesloLGL Nerd Font";
        package = pkgs.nerd-fonts.meslo-lg;
      }
    ];
  };

  services = {
    fstrim.enable = true;
    fstrim.interval = "weekly";
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      # utils
      fio # disk benchmark
      lm_sensors

      # Networking
      pciutils
      usbutils
      nvme-cli
      ;

    inherit (pkgs.gst_all_1)
      gst-devtools
      gst-editing-services
      gst-plugins-bad
      gst-plugins-base
      gst-plugins-good
      gst-plugins-ugly
      gst-rtsp-server
      gst-vaapi
      gstreamer
      gstreamermm
      ;
  };

  programs = {
    nix-index.enableBashIntegration = true;
    nix-index.enableZshIntegration = true;
    dconf.enable = config.services.xserver.enable;
  };

  nixpkgs.overlays = [
    addUnstablePackages
  ];
}
