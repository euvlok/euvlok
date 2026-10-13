{ euvlokInputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.zen-browser;
  packages = import euvlokInputs.zen-browser { inherit pkgs; };
  sources = lib.trivial.importJSON "${euvlokInputs.zen-browser}/sources.json";
  wrapZen = import "${euvlokInputs.zen-browser}/wrap-zen.nix" pkgs.wrapFirefox;
  mkFirefoxModule = import "${euvlokInputs.home-manager}/modules/programs/firefox/mkFirefoxModule.nix";
in
{
  imports = [
    (mkFirefoxModule {
      modulePath = [
        "programs"
        "zen-browser"
      ];
      name = "Zen";
      wrappedPackageName = "zen-browser";
      unwrappedPackageName = "zen-browser-unwrapped";
      platforms = {
        linux.configPath = "${config.xdg.configHome}/zen";
        darwin = {
          configPath = "${config.home.homeDirectory}/Library/Application Support/Zen";
          defaultsId = "app.zen-browser.zen";
        };
      };
    })
  ];

  config = lib.modules.mkIf cfg.enable {
    programs.zen-browser = {
      # Gecko reads policies beside its unwrapped executable on Linux
      # macOS keeps the signed bundle and uses the defaults domain
      package = lib.modules.mkDefault (
        if pkgs.stdenv.hostPlatform.isDarwin then
          packages.twilight-unwrapped
        else
          wrapZen
            (packages.twilight-unwrapped.overrideAttrs (old: {
              postInstall = (old.postInstall or "") + ''
                policyPath="$out/lib/${packages.twilight-unwrapped.libName}/distribution/policies.json"
                rm -f "$policyPath"
                ln -s ${config.euvlok.home.firefox.zen-browser.policiesFile} "$policyPath"
              '';
            }))
            {
              inherit (cfg) nativeMessagingHosts;
            }
      );
      policies.SecurityDevices = lib.modules.mkIf pkgs.stdenv.hostPlatform.isLinux {
        "System Trust" = "${pkgs.p11-kit}/lib/pkcs11/p11-kit-trust.so";
      };
      release = lib.modules.mkDefault (
        cfg.package.firefoxVersion
          or (cfg.package.unwrapped.firefoxVersion or sources.variants.twilight.x86_64-linux.firefoxVersion)
      );
    };

    mozilla.firefoxNativeMessagingHosts =
      cfg.nativeMessagingHosts ++ lib.lists.optional (cfg.finalPackage != null) cfg.finalPackage;
  };
}
