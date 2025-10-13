{
  pkgsUnstable,
  lib,
  config,
  osConfig,
  ...
}:
let
  browserPackages = {
    brave = pkgsUnstable.brave;
    chromium = pkgsUnstable.chromium.override { enableWideVine = true; };
    google-chrome = pkgsUnstable.google-chrome;
    ungoogled-chromium = pkgsUnstable.ungoogled-chromium;
    vivaldi = pkgsUnstable.vivaldi;
  };

  chromiumProgramUsers = [
    "chromium"
    "google-chrome"
    "ungoogled-chromium"
  ];

  getProgramName =
    name:
    if lib.elem name chromiumProgramUsers then
      "chromium"
    else if name == "brave" then
      "brave"
    else if name == "vivaldi" then
      "vivaldi"
    else
      throw "Unknown browser name: ${name}";

  commonArgs = {
    dictionaries = builtins.attrValues {
      inherit (pkgsUnstable.hunspellDictsChromium) en_US de_DE fr_FR;
    };
    commandLineArgs = [
      # Debug
      "--enable-logging=stderr"
    ]
    ++ lib.optionals osConfig.nixpkgs.hostPlatform.isLinux [
      # Hardware Acceleration
      "--ignore-gpu-blocklist"
      "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"

      # Wayland
      "--ozone-platform-hint=wayland"
      "--enable-wayland-ime"
      "--wayland-text-input-version=3"
      "--enable-features=TouchpadOverscrollHistoryNavigation"
    ];
  };
  commonExtensions = (pkgsUnstable.callPackage ./extensions.nix { inherit config; });
in
{
  options.hm.chromium = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        # The arguments `name` and `config` are provided to the submodule function.
        # `name` is the attribute name (e.g., "brave")
        # `config` is the set of resolved options for *this specific browser instance*
        { name, config, ... }:
        {
          options = {
            enable = lib.mkEnableOption "this Chromium-based browser instance";

            package = lib.mkOption {
              type = lib.types.package;
              default = browserPackages.${name};
              defaultText = lib.literalExpression "browserPackages.${name}";
              description = "The package to use for this browser instance";
            };

            extraCommandLineArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Extra command line arguments specific to this browser";
              example = [ "--incognito" ];
            };

            extraExtensions = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = "Extra extensions specific to this browser instance";
            };
          };

          config = lib.mkIf (config.enable && osConfig.nixpkgs.hostPlatform.isLinux) {
            "programs.${getProgramName name}" = {
              enable = true;
              package = config.package; # `config` here is local to the submodule
              dictionaries = commonArgs.dictionaries;
              extensions = commonExtensions ++ config.extraExtensions;
              commandLineArgs =
                commonArgs.commandLineArgs
                ++ (lib.optionals (lib.elem name chromiumProgramUsers) [
                  "--disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled"
                ])
                ++ config.extraCommandLineArgs;
            };
          };
        }
      )
    );
    default = { };
    description = "Configuration for one or more Chromium-based browsers";
    example = lib.literalExpression ''
      {
        ungoogled-chromium = { enable = true; };
        brave = { enable = true; extraCommandLineArgs = [ "--incognito" ]; };
        vivaldi = { enable = true; extraExtensions = lib.flatten [ (pkgs.callPackage ./extensions.nix { inherit config; }) ]; };
      }
    '';
  };

  config = {
    assertions = [
      {
        assertion =
          let
            enabledBrowsers = lib.filterAttrs (_: browserCfg: browserCfg.enable) config.hm.chromium;
            enabledChromiumProgramUsers = lib.intersectLists chromiumProgramUsers (
              lib.attrNames enabledBrowsers
            );
          in
          lib.length enabledChromiumProgramUsers <= 1;

        message = ''
          You have enabled multiple browsers that all use the 'programs.chromium' home-manager module:
            ${lib.concatStringsSep ", " (
              let
                enabledBrowsers = lib.filterAttrs (_: browserCfg: browserCfg.enable) config.hm.chromium;
              in
              lib.intersectLists chromiumProgramUsers (lib.attrNames enabledBrowsers)
            )}
          Please enable only one of them at a time.
        '';
      }
    ];
  };
}
