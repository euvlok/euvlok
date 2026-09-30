{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  jq,
  moreutils,
  chatgpt,
  helium ? false,
  marketplaceName,
  pluginNames,
}:
let
  isDarwin = stdenvNoCC.hostPlatform.isDarwin;
  version = if isDarwin then "26.1002.52244" else lib.getVersion chatgpt;
  darwinSources = {
    aarch64-darwin = {
      arch = "arm64";
      hash = "sha256-Pxhv1tisEm6dZpNs78++EWQA4PGfOa4WfiUXAjC4VMU=";
    };
    x86_64-darwin = {
      arch = "x64";
      hash = "sha256-NkJJL03jHmFdtW79d8vkjWzXgUSMygjNr0x5SdZ6xfY=";
    };
  };
  darwinSource = darwinSources.${stdenvNoCC.hostPlatform.system};
  linux = {
    installations = [
      {
        commands = [
          "helium"
          "helium-browser"
        ];
        userDataDirName = "net.imput.helium";
      }
    ];
    nativeMessagingManifestDirectories = [ ".config/net.imput.helium/NativeMessagingHosts" ];
    configHomeEnvironmentVariables = [ "XDG_CONFIG_HOME" ];
    processNames = [
      "helium"
      "helium-browser"
    ];
    userDataDirectorySegments = [
      ".config"
      "net.imput.helium"
    ];
  };
  macos = {
    applicationNames = [ "Helium.app" ];
    bundleId = "net.imput.helium";
    nativeMessagingManifestDirectories = [
      "Library/Application Support/net.imput.helium/NativeMessagingHosts"
    ];
    processNames = [
      "Helium"
      "Helium Helper"
    ];
    userDataDirectorySegments = [
      "Library"
      "Application Support"
      "net.imput.helium"
    ];
  };
  heliumBrowser = builtins.toJSON {
    displayName = "Helium";
    shortDisplayName = "Helium";
    inherit linux macos;
  };
  browserPlugins = lib.intersectLists pluginNames [
    "browser"
    "chrome"
  ];
  registryBoundary = ''}},edge:{backendCompatibilityKey:"chrome",displayName:"Microsoft Edge"'';
  heliumRegistryBoundary = ''},...${heliumBrowser}},edge:{backendCompatibilityKey:"chrome",displayName:"Microsoft Edge"'';
  guidance = ''
    # Browser

    This installation controls Helium. For an explicit Helium request,
    use `agent.browsers.get("chrome")` and read its full documentation.
    The `chrome` selector is Helium's extension transport compatibility key.
    Use Helium for diagnostics, launch paths, profiles, and extension setup.
  '';
in
stdenvNoCC.mkDerivation {
  pname = "codex-bundled-plugins";
  inherit version;
  src =
    if isDarwin then
      fetchurl {
        url = "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-${darwinSource.arch}-${version}.zip";
        inherit (darwinSource) hash;
      }
    else
      "${chatgpt.unwrapped}/lib/chatgpt/resources/plugins/openai-bundled";
  nativeBuildInputs = [
    jq
    moreutils
  ]
  ++ lib.lists.optional isDarwin unzip;
  # Extract only the plugins; stdenv handles source permissions and hooks
  unpackCmd = lib.optionalString isDarwin ''
    unzip -q "$curSrc" 'ChatGPT.app/Contents/Resources/plugins/openai-bundled/*'
  '';
  sourceRoot =
    if isDarwin then "ChatGPT.app/Contents/Resources/plugins/openai-bundled" else "openai-bundled";
  dontConfigure = true;
  dontBuild = true;
  # Preserve the bundled native hosts' signatures and ELF interpreters
  dontFixup = true;
  postPatch = ''
    ${lib.strings.toShellVars {
      inherit marketplaceName;
      selectedPlugins = builtins.toJSON pluginNames;
    }}
    jq --arg name "$marketplaceName" \
      --argjson selected "$selectedPlugins" \
      '.name = $name | .plugins |= map(select(.name as $name | $selected | index($name)))' \
      .agents/plugins/marketplace.json | sponge .agents/plugins/marketplace.json
  ''
  + lib.optionalString helium ''
    ${lib.strings.toShellVars {
      inherit
        browserPlugins
        heliumBrowser
        registryBoundary
        heliumRegistryBoundary
        guidance
        ;
    }}
    for name in "''${browserPlugins[@]}"; do
      plugin="plugins/$name"
      [[ -d "$plugin" ]] || continue
      # Override platform settings while preserving Chrome's transport fields
      for script in "$plugin"/scripts/*.mjs; do
        if grep -Fq 'backendCompatibilityKey:"chrome",displayName:"Google Chrome"' "$script"; then
          substituteInPlace "$script" \
            --replace-fail "$registryBoundary" "$heliumRegistryBoundary"
        fi
      done
      grep -Fq "$heliumRegistryBoundary" \
        "$plugin/scripts/browser-service.mjs"
      diagnostics="$plugin/scripts/extension-ids.json"
      if [[ -f "$diagnostics" ]]; then
        jq --argjson browser "$heliumBrowser" \
          '(.browserDiagnostics[] | select(.browserFamily == "chrome")) |=
           (. += $browser | .linux |= (.commands = .installations[0].commands | del(.installations)))' \
          "$diagnostics" | sponge "$diagnostics"
      fi
      skill="$plugin/skills/control-chrome/SKILL.md"
      if [[ -f "$skill" ]]; then
        substituteInPlace "$skill" \
          --replace-quiet 'Google Chrome' 'Helium' \
          --replace-fail 'Chrome' 'Helium' \
          --replace-fail '# Browser' "$guidance"
        metadata="$plugin/.codex-plugin/plugin.json"
        jq '.interface |= (.displayName = "Helium" |
            .shortDescription |= (if type == "string" then gsub("Chrome"; "Helium") else . end) |
            .longDescription |= (if type == "string" then gsub("Chrome"; "Helium") else . end))' \
          "$metadata" | sponge "$metadata"
      fi
    done
  '';
  installPhase = ''
    runHook preInstall
    ${lib.strings.toShellVar "pluginNames" pluginNames}
    mkdir -p "$out/plugins" "$out/.agents/plugins"
    for name in "''${pluginNames[@]}"; do
      if [[ -d "plugins/$name" ]]; then
        cp -a "plugins/$name" "$out/plugins/"
      fi
    done
    cp .agents/plugins/marketplace.json "$out/.agents/plugins/"
    runHook postInstall
  '';
  meta = {
    description = "ChatGPT's bundled Codex marketplace with optional Helium patches";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
