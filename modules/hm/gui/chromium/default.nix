{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.hm.chromium;

  chromiumFeatures = [
    "ForceEnableWebGpuInterop"
    "ReduceOpsTaskSplitting"
    "TouchpadOverscrollHistoryNavigation"
    "VaapiVideoDecoder"
    "VaapiVideoEncoder"
  ]
  ++ lib.lists.optionals (cfg.browser == "helium-browser") [
    "BrowsingTopics"
    "InterestGroupStorage"
  ];

  chromiumDisabledFeatures = lib.lists.optionals (cfg.browser == "helium-browser") [
    "ExtensionManifestV2Unsupported"
    "ExtensionManifestV2Disabled"
  ];

  browserPackages = {
    chromium = pkgs.chromium.override { enableWideVine = true; };
    helium-browser = pkgs.eupkgs.helium-browser;
    inherit (pkgs)
      brave
      google-chrome
      ungoogled-chromium
      ;
  };

  extensions = lib.lists.unique (
    (pkgs.callPackage ./extensions.nix { inherit config; }) ++ cfg.extraExtensions
  );

  # Helium bundles uBlock Origin and supports Kagi natively
  heliumExtensions = builtins.filter (
    ext:
    !(builtins.elem ext.id [
      "cjpalhdlnbpafiamejdnhcphjbkeiagm"
      "cdglnehniifkbagbbombnjghhcihifij"
    ])
  ) extensions;

  chromiumExternalExtension = ext: {
    name = "net.imput.helium/External Extensions/${ext.id}.json";
    value.text = builtins.toJSON {
      external_crx = ext.crxPath;
      external_version = ext.version;
    };
  };
in
{
  options.hm.chromium = {
    enable = lib.options.mkEnableOption "Chromium-based browsers";

    browser = lib.options.mkOption {
      type = lib.types.enum (lib.attrsets.attrNames browserPackages);
      default = "ungoogled-chromium";
      description = "The browser package to use.";
    };

    extraExtensions = lib.options.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "A list of extra extensions to append to the base list.";
      example = ''
        (pkgs.callPackage ./my-extensions.nix { })
      '';
    };
  };

  config = lib.modules.mkIf cfg.enable {
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

      extensions = if cfg.browser == "helium-browser" then lib.modules.mkForce [ ] else extensions;

      commandLineArgs = [
        # Debug
        "--enable-logging=stderr"
        "--enable-features=${lib.strings.concatStringsSep "," chromiumFeatures}"
      ]
      ++ lib.lists.optionals (chromiumDisabledFeatures != [ ]) [
        "--disable-features=${lib.strings.concatStringsSep "," chromiumDisabledFeatures}"
      ]
      ++ lib.lists.optionals pkgs.stdenvNoCC.isLinux [
        "--ignore-gpu-blocklist"

        # Wayland
        "--enable-wayland-ime"
        "--wayland-text-input-version=3"
      ];
    };

    xdg.configFile = lib.modules.mkIf (cfg.browser == "helium-browser") (
      builtins.listToAttrs (map chromiumExternalExtension heliumExtensions)
    );
  };
}
