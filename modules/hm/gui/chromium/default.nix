{
  pkgsUnstable,
  lib,
  config,
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
        assertion = pkgsUnstable.stdenvNoCC.isLinux;
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
      extensions = (pkgsUnstable.callPackage ./extensions.nix { inherit config; });
      commandLineArgs = [
        # Debug
        "--enable-logging=stderr"
      ]
      ++ lib.optionals (lib.elem config.hm.chromium.browser [
        "chromium"
        "google-chrome"
        "microsoft-edge"
      ]) [ "--disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled" ] # Enable mv2 while its still possible
      ++ lib.optionals pkgsUnstable.stdenvNoCC.isLinux [
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
