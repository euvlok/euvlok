{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.hm.chromium;

  browserPackages = {
    chromium = pkgs.chromium.override { enableWideVine = true; };
    inherit (pkgs)
      brave
      google-chrome
      ungoogled-chromium
      ;
  };
in
{
  options.hm.chromium = {
    enable = lib.mkEnableOption "Chromium-based browsers";

    browser = lib.mkOption {
      type = lib.types.enum (lib.attrNames browserPackages);
      default = "ungoogled-chromium";
      description = "The browser package to use.";
    };

    extraExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "A list of extra extensions to append to the base list.";
      example = ''
        (pkgs.callPackage ./my-extensions.nix { })
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenvNoCC.isLinux;
        message = "hm.chromium is only available on Linux";
      }
    ];
    programs.chromium = {
      enable = true;
      package = browserPackages.${cfg.browser};
      dictionaries = builtins.attrValues {
        inherit (pkgs.hunspellDictsChromium) en_US de_DE fr_FR;
      };

      extensions = lib.unique (
        (pkgs.callPackage ./extensions.nix { inherit config; }) ++ cfg.extraExtensions
      );

      commandLineArgs = [
        # Debug
        "--enable-logging=stderr"
      ]
      ++ lib.optionals (lib.elem cfg.browser [
        "chromium"
        "google-chrome"
      ]) [ "--disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled" ] # Enable mv2 while it's still possible
      ++ lib.optionals pkgs.stdenvNoCC.isLinux [
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
