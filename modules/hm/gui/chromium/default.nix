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
    helium-browser = pkgs.eupkgs.helium-browser;
    inherit (pkgs)
      brave
      google-chrome
      ungoogled-chromium
      ;
  };

  extensions = lib.unique (
    (pkgs.callPackage ./extensions.nix { inherit config; }) ++ cfg.extraExtensions
  );

  chromiumExternalExtension = ext: {
    name = "helium/External Extensions/${ext.id}.json";
    value.text = builtins.toJSON {
      external_crx = ext.crxPath;
      external_version = ext.version;
    };
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

      extensions = if cfg.browser == "helium-browser" then lib.mkForce [ ] else extensions;

      commandLineArgs = [
        # Debug
        "--enable-logging=stderr"
      ]
      ++ lib.optionals (cfg.browser == "helium-browser") [
        "--disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled"
      ] # Enable mv2 in Helium.
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

    xdg.configFile = lib.mkIf (cfg.browser == "helium-browser") (
      builtins.listToAttrs (map chromiumExternalExtension extensions)
    );
  };
}
