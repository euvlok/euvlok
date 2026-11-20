{ euvlokInputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  settings = config.euvlok.home.firefox;
  tweezle = euvlokInputs.tweezle.packages.${pkgs.stdenv.hostPlatform.system}.default;
  variants = {
    firefox = "firefox";
    floorp = "floorp";
    librewolf = "librewolf";
    zen-browser = "zen";
  };
  setFloorpRelease = pkgs.buildPackages.writers.writePython3 "floorp-language-pack-release" { } ''
    import configparser
    import sys
    from pathlib import Path

    platform = configparser.ConfigParser()
    platform.read(sys.argv[2])
    release = platform["Build"]["Milestone"]
    content = Path(sys.argv[1]).read_text()
    content = content.replace("__FLOORP_GECKO_RELEASE__", release)
    Path(sys.argv[3]).write_text(content)
  '';
  renderPolicyPlist = pkgs.buildPackages.writers.writePython3 "firefox-policy-plist" { } ''
    import json
    import plistlib
    import sys

    with open(sys.argv[1]) as source:
        policies = json.load(source)["policies"]
    policies["EnterprisePoliciesEnabled"] = True
    with open(sys.argv[2], "wb") as destination:
        plistlib.dump(policies, destination)
  '';
in
{
  config = lib.modules.mkMerge (
    lib.attrsets.mapAttrsToList (
      name: variant:
      let
        browser = config.programs.${name};
        floorpLanguagePacks = name == "floorp" && settings.languagePacks != [ ];
        languageRelease = if floorpLanguagePacks then "__FLOORP_GECKO_RELEASE__" else browser.release;
        extensions = lib.lists.unique (
          settings.extraExtensions
          ++ settings.${name}.extraExtensions
          ++ lib.lists.map (language: {
            id = "langpack-${language}@firefox.mozilla.org";
            install_url = "https://releases.mozilla.org/pub/firefox/releases/${languageRelease}/linux-x86_64/xpi/${language}.xpi";
            installation_mode = "normal_installed";
          }) settings.languagePacks
        );
        template = euvlokInputs.tweezle.lib.generateConfig {
          inherit pkgs;
          name = "${name}-extensions.toml";
          settings.firefox = {
            inherit variant extensions;
            policies = lib.attrsets.filterAttrs (_: value: value != { }) browser.policies;
          };
        };
        # Floorp's package version differs from its Gecko language-pack version
        extensionConfigFile =
          if !floorpLanguagePacks then
            template
          else
            let
              unwrapped = browser.package.unwrapped;
              platformIni =
                if pkgs.stdenv.hostPlatform.isDarwin then
                  "${unwrapped}/Applications/${unwrapped.applicationName}.app/Contents/Resources/platform.ini"
                else
                  "${unwrapped}/lib/${unwrapped.libName}/platform.ini";
            in
            pkgs.runCommandLocal "${name}-extensions.toml" { } ''
              ${setFloorpRelease} ${template} ${lib.strings.escapeShellArg platformIni} "$out"
            '';
        policiesFile = pkgs.runCommandLocal "${name}-tweezle-policies.json" { } ''
          ${lib.meta.getExe tweezle} policy render ${extensionConfigFile} --output "$out"
        '';
        policiesPlist = pkgs.runCommandLocal "${name}-tweezle-policies.plist" { } ''
          ${renderPolicyPlist} ${policiesFile} "$out"
        '';
      in
      lib.modules.mkMerge [
        {
          euvlok.home.firefox.${name} = {
            extensionConfigFile = if browser.enable then extensionConfigFile else null;
            policiesFile = if browser.enable then policiesFile else null;
          };
        }
        (lib.modules.mkIf browser.enable {
          programs.tweezle.fileSources = {
            "tweezle/${name}-extensions.toml" = extensionConfigFile;
            "tweezle/${name}-policies.json" = policiesFile;
          };

          # Policies are browser-wide; profile activation only writes preferences
          # User defaults preserve macOS application signatures
          home.activation."${name}ExtensionPolicies" =
            lib.modules.mkIf (pkgs.stdenv.hostPlatform.isDarwin && browser.darwinDefaultsId != null)
              (
                lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
                  run /usr/bin/defaults import ${lib.strings.escapeShellArg browser.darwinDefaultsId} ${policiesPlist}
                ''
              );
        })
      ]
    ) variants
  );
}
