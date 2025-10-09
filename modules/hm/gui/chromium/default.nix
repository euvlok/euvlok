{
  pkgsUnstable,
  lib,
  config,
  osConfig,
  ...
}:
{
  options.hm.chromium = {
    enable = lib.mkEnableOption "Chromium";
    browser = lib.mkOption {
      default = "ungoogled-chromium";
      description = "Select the Chromium browser variant";
      type = lib.types.enum [
        "brave"
        "chromium"
        "google-chrome"
        "microsoft-edge"
        "ungoogled-chromium"
        "vivaldi"
      ];
    };
  };

  config = lib.mkIf config.hm.chromium.enable {
    assertions = [
      {
        assertion = osConfig.nixpkgs.hostPlatform.isLinux;
        message = "Chromium is only available on Linux";
      }
    ];
    programs.chromium = {
      enable = true;
      package =
        let
          browserPackages = {
            chromium = pkgsUnstable.chromium.override { enableWideVine = true; };
            inherit (pkgsUnstable)
              brave
              google-chrome
              microsoft-edge
              ungoogled-chromium
              vivaldi
              ;
          };
        in
        browserPackages.${config.hm.chromium.browser};
      dictionaries = builtins.attrValues {
        inherit (pkgsUnstable.hunspellDictsChromium) en_US de_DE fr_FR;
      };
      extensions = [ (pkgsUnstable.callPackage ./extensions.nix { }) ];
      commandLineArgs = [
        # Debug
        "--enable-logging=stderr"
      ]
      ++ lib.optionals (config.hm.chromium.browser == "chromium" || "google-chrome" || "microsoft-edge") [
        # Enable mv2 while its still possible
        "--disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled"
      ]
      ++ lib.optionals osConfig.nixpkgs.hostPlatform.isLinux [
        "--ignore-gpu-blocklist"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"

        # Wayland
        "--ozone-platform-hint=wayland"
        "--enable-wayland-ime"
        "--wayland-text-input-version=3"
        "--enable-features=TouchpadOverscrollHistoryNavigation"
      ];
    };
  };
}
