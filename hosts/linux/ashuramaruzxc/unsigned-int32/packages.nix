{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      lm_sensors

      # utils
      binutils
      findutils
      fio # disk benchmark
      util-linux

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
}
