{ euvlokInputs }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.euvlok.home.chromium;
  isDarwin = pkgs.stdenvNoCC.hostPlatform.isDarwin;
  isLinux = pkgs.stdenvNoCC.hostPlatform.isLinux;
  platform = if isDarwin then "macos" else "linux";

  chromiumFeatures = [
    "ForceEnableWebGpuInterop"
    "ReduceOpsTaskSplitting"
    "TouchpadOverscrollHistoryNavigation"
  ]
  ++ lib.lists.optionals isLinux [
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

  browserPackage = browserPackages.${cfg.browser};

  browserExecutables = {
    brave = "brave";
    chromium = "chromium";
    google-chrome = "google-chrome-stable";
    helium-browser = "helium-browser";
    ungoogled-chromium = "chromium";
  };
  browserExecutable = browserExecutables.${cfg.browser};

  browserMacOSAppDirs = {
    brave = "/Applications/Brave Browser.app";
    chromium = "/Applications/Chromium.app";
    google-chrome = "/Applications/Google Chrome.app";
    helium-browser = "${browserPackage}/Applications/Helium.app";
    ungoogled-chromium = "/Applications/Chromium.app";
  };

  browserMacOSLaunchers = {
    brave = "Contents/MacOS/Brave Browser";
    chromium = "Contents/MacOS/Chromium";
    google-chrome = "Contents/MacOS/Google Chrome";
    helium-browser = "Contents/MacOS/Helium";
    ungoogled-chromium = "Contents/MacOS/Chromium";
  };

  browserProfileRoots =
    if isDarwin then
      {
        brave = "BraveSoftware/Brave-Browser";
        chromium = "Chromium";
        google-chrome = "Google/Chrome";
        helium-browser = "net.imput.helium";
        ungoogled-chromium = "Chromium";
      }
    else
      {
        brave = "BraveSoftware/Brave-Browser";
        chromium = "chromium";
        google-chrome = "google-chrome";
        helium-browser = "net.imput.helium";
        ungoogled-chromium = "chromium";
      };
  browserProfileRoot = browserProfileRoots.${cfg.browser};

  chromiumCommandLineArgs = [
    # Debug
    "--enable-logging=stderr"
    "--enable-features=${lib.strings.concatStringsSep "," chromiumFeatures}"
  ]
  ++ lib.lists.optional (
    chromiumDisabledFeatures != [ ]
  ) "--disable-features=${lib.strings.concatStringsSep "," chromiumDisabledFeatures}"
  ++ lib.lists.optionals isLinux [
    "--ignore-gpu-blocklist"

    # Wayland
    "--enable-wayland-ime"
    "--wayland-text-input-version=3"
  ];

  browserSettings = {
    name = cfg.browser;
    executable_name = browserExecutable;
    flags = chromiumCommandLineArgs;
  }
  // lib.attrsets.optionalAttrs isLinux {
    linux = {
      app_dir = "${config.home.profileDirectory}/bin";
      launcher_name = browserExecutable;
    };

    paths.linux = {
      profile_dir = "\${config_home}/${browserProfileRoot}/Default";
      external_extension_dirs = [ "\${config_home}/${browserProfileRoot}/External Extensions" ];
    };
  }
  // lib.attrsets.optionalAttrs isDarwin {
    macos = {
      app_dir = browserMacOSAppDirs.${cfg.browser};
      launcher_path = browserMacOSLaunchers.${cfg.browser};
    };

    paths.macos = {
      profile_dir = "\${home}/Library/Application Support/${browserProfileRoot}/Default";
      external_extension_dirs = [
        "\${home}/Library/Application Support/${browserProfileRoot}/External Extensions"
      ];
    };
  };

  extensionCatalog = lib.attrsets.zipAttrsWith (_: lib.lists.concatLists) [
    (import ./extensions.nix { inherit config lib; })
    cfg.extraExtensions
  ];

  # Helium bundles uBlock Origin and supports Kagi natively.
  heliumExtensionIds = [
    "cjpalhdlnbpafiamejdnhcphjbkeiagm"
    "cdglnehniifkbagbbombnjghhcihifij"
  ];
  managedExtensions = lib.attrsets.mapAttrs (
    _: extensions:
    lib.lists.filter (
      extension: cfg.browser != "helium-browser" || !(lib.lists.elem extension.id heliumExtensionIds)
    ) extensions
  ) extensionCatalog;
in
{
  options.euvlok.home.chromium = {
    enable = lib.options.mkEnableOption "Chromium-based browsers";

    browser = lib.options.mkOption {
      type = lib.types.enum (lib.attrsets.attrNames browserPackages);
      default = "ungoogled-chromium";
      description = "The browser package to use.";
    };

    extraExtensions = lib.options.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.attrs);
      default = { };
      description = "Extra 4evy/browser extension catalog entries to append to the base catalog.";
      example = lib.options.literalExpression ''
        {
          chrome_store = [
            {
              id = "nngceckbapebfimnlniiiahkandclblb";
              name = "Bitwarden";
            }
          ];
        }
      '';
    };

    configureOnActivation = lib.options.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install and update extensions with 4evy/browser during Home Manager activation.";
    };
  };

  imports = [ euvlokInputs.browser.homeModules.default ];

  config = lib.modules.mkIf cfg.enable {
    assertions = [
      {
        assertion = isLinux || isDarwin;
        message = "euvlok.home.chromium is only available on Linux and macOS";
      }
    ];
    programs.chromium = lib.modules.mkIf isLinux {
      enable = true;
      package = browserPackage;
      dictionaries = builtins.attrValues {
        inherit (pkgs.hunspellDictsChromium) en_US de_DE fr_FR;
      };

      # 4evy/browser is the single extension installer.
      extensions = lib.modules.mkForce [ ];

      commandLineArgs = chromiumCommandLineArgs;
    };

    programs.browser = {
      enable = true;
      settings = {
        browser = browserSettings;

        extensions = managedExtensions // {
          chrome_store_update_url = "https://clients2.google.com/service/update2/crx";
        };
      };
    };

    home.packages = lib.lists.optional isDarwin browserPackage;

    home.activation.configureChromium = lib.modules.mkIf cfg.configureOnActivation (
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run ${lib.meta.getExe config.programs.browser.package} apply \
          ${config.programs.browser.configFile} \
          --platform ${platform} \
          --no-profile
      ''
    );
  };
}
