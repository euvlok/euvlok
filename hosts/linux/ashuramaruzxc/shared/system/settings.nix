{ pkgs, config, ... }:
{
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

    # inherit (pkgs.gst_all_1)
    #   gst-devtools
    #   gst-editing-services
    #   gst-plugins-bad
    #   gst-plugins-base
    #   gst-plugins-good
    #   gst-plugins-ugly
    #   gst-rtsp-server
    #   gst-vaapi
    #   gstreamer
    #   gstreamermm
    #   ;
  };

  programs = {
    nix-index.enableBashIntegration = true;
    nix-index.enableZshIntegration = true;
    dconf.enable = config.services.xserver.enable;
  };
}
