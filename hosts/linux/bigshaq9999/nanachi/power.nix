_: {
  # TLP does not run when used with KDE or GNOME.
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = true; # Disabled for Plasma
  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

    PLATFORM_PROFILE_ON_AC = "balanced";
    PLATFORM_PROFILE_ON_BAT = "low-power";

    CPU_BOOST_ON_AC = 1;
    CPU_BOOST_ON_BAT = 0;

    AMDGPU_ABM_LEVEL_ON_AC = 0;
    AMDGPU_ABM_LEVEL_ON_BAT = 3;

    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "on";

    CPU_MIN_PERF_ON_AC = 0;
    CPU_MAX_PERF_ON_AC = 100;
    CPU_MIN_PERF_ON_BAT = 0;
    CPU_MAX_PERF_ON_BAT = 50;

    START_CHARGE_THRESH_BAT0 = 20;
    STOP_CHARGE_THRESH_BAT0 = 80;

    START_CHARGE_THRESH_BAT1 = 20;
    STOP_CHARGE_THRESH_BAT1 = 80;
  };
}
