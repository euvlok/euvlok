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

  # Keep package and launcher/profile identity together for each browser
  browsers = {
    brave = {
      package = pkgs.brave;
      executable = "brave";
      profileRoot = "BraveSoftware/Brave-Browser";
      macos = {
        app_dir = "/Applications/Brave Browser.app";
        launcher_path = "Contents/MacOS/Brave Browser";
      };
    };
    chromium = {
      package = pkgs.chromium.override { enableWideVine = true; };
      executable = "chromium";
      profileRoot = if isDarwin then "Chromium" else "chromium";
      macos = {
        app_dir = "/Applications/Chromium.app";
        launcher_path = "Contents/MacOS/Chromium";
      };
    };
    google-chrome = {
      package = pkgs.google-chrome;
      executable = "google-chrome-stable";
      profileRoot = if isDarwin then "Google/Chrome" else "google-chrome";
      macos = {
        app_dir = "/Applications/Google Chrome.app";
        launcher_path = "Contents/MacOS/Google Chrome";
      };
    };
    helium-browser = rec {
      package = pkgs.eupkgs.helium-browser;
      executable = "helium-browser";
      profileRoot = "net.imput.helium";
      macos = {
        app_dir = "${package}/Applications/Helium.app";
        launcher_path = "Contents/MacOS/Helium";
      };
    };
    ungoogled-chromium = {
      package = pkgs.ungoogled-chromium;
      executable = "chromium";
      profileRoot = if isDarwin then "Chromium" else "chromium";
      macos = {
        app_dir = "/Applications/Chromium.app";
        launcher_path = "Contents/MacOS/Chromium";
      };
    };
  };
  browser = browsers.${cfg.browser};

  chromiumCommandLineArgs = lib.cli.toCommandLineGNU { } {
    enable-logging = "stderr";
    enable-features = lib.strings.concatStringsSep "," chromiumFeatures;
    disable-features =
      if chromiumDisabledFeatures == [ ] then
        null
      else
        lib.strings.concatStringsSep "," chromiumDisabledFeatures;
    ignore-gpu-blocklist = isLinux;
    enable-wayland-ime = isLinux;
    wayland-text-input-version = if isLinux then 3 else null;
  };

  extensionType = lib.types.submodule {
    freeformType = (pkgs.formats.json { }).type;
    options.id = lib.options.mkOption {
      type = lib.types.strMatching "[a-p]{32}";
      description = "The Chromium extension ID, consisting of 32 letters from a to p.";
    };
  };

  browserSettings = {
    name = cfg.browser;
    executable_name = browser.executable;
    flags = chromiumCommandLineArgs;
  }
  // lib.attrsets.optionalAttrs isLinux {
    linux = {
      app_dir = "${config.home.profileDirectory}/bin";
      launcher_name = browser.executable;
    };

    paths.linux = {
      profile_dir = "\${config_home}/${browser.profileRoot}/Default";
      external_extension_dirs = [ "\${config_home}/${browser.profileRoot}/External Extensions" ];
    };
  }
  // lib.attrsets.optionalAttrs isDarwin {
    macos = browser.macos;

    paths.macos = {
      profile_dir = "\${home}/Library/Application Support/${browser.profileRoot}/Default";
      external_extension_dirs = [
        "\${home}/Library/Application Support/${browser.profileRoot}/External Extensions"
      ];
    };
  };

  extensionCatalog = lib.attrsets.zipAttrsWith (_: lib.lists.concatLists) [
    (import ./extensions.nix { inherit config lib; })
    cfg.extraExtensions
  ];

  # Helium bundles uBlock Origin and supports Kagi natively
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
      type = lib.types.enum (lib.attrsets.attrNames browsers);
      default = "ungoogled-chromium";
      description = "The browser package to use.";
    };

    extraExtensions = lib.options.mkOption {
      type = lib.types.attrsWith {
        placeholder = "source";
        elemType = lib.types.listOf extensionType;
      };
      default = { };
      description = "Extra Tweezle extension catalog entries to append to the base catalog.";
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
  };

  imports = [ euvlokInputs.tweezle.homeModules.default ];

  config = lib.modules.mkIf cfg.enable {
    euvlok.home.chromium.extraExtensions.chrome_store =
      lib.modules.mkIf
        (
          (config.euvlok.home.codex.enable or false)
          && (config.euvlok.home.codex.desktop.enable or false)
          && (config.euvlok.home.codex.desktop.helium.enable or false)
          && (config.programs.codex.settings.plugins."chrome@euvlok-chatgpt-bundled".enabled or false)
        )
        [
          {
            id = "hehggadaopoacecdllhhajmbjkdcmajg";
            name = "ChatGPT";
          }
        ];
    assertions = [
      {
        assertion = isLinux || isDarwin;
        message = "euvlok.home.chromium is only available on Linux and macOS";
      }
    ];
    programs.chromium = lib.modules.mkIf isLinux {
      enable = true;
      package = browser.package;
      dictionaries = lib.attrsets.attrValues {
        inherit (pkgs.hunspellDictsChromium) en_US de_DE fr_FR;
      };

      # Tweezle is the single extension installer
      extensions = lib.modules.mkForce [ ];

      commandLineArgs = chromiumCommandLineArgs;
    };

    programs.tweezle = {
      enable = true;
      configurations.chromium.chromium = browserSettings // {
        extensions = managedExtensions // {
          chrome_store_update_url = "https://clients2.google.com/service/update2/crx";
        };
      };
    };

    home.packages = lib.lists.optional isDarwin browser.package;
  };
}
