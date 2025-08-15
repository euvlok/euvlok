{
  pkgs,
  pkgsUnstable,
  ...
}:
{
  programs.adb.enable = true;
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

    inherit (pkgs) piper; # mouse settings
  };

  services.udev.extraRules = ''
    # SayoDevice O3C
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1d6b", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1d6b", TAG+="uaccess"

    # SayoDevice O3C++ / CM51+
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="8089", TAG+="uaccess" 
    SUBSYSTEM=="usb", ATTRS{idVendor}=="8089", TAG+="uaccess"
  '';
  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
    package = pkgs.openrgb-with-all-plugins;
  };
  hardware.opentabletdriver = {
    enable = true;
    package = pkgsUnstable.opentabletdriver;
    daemon.enable = true;
  };
  services.ratbagd.enable = true;
}
