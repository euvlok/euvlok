{ jetbrainsPlugins }:
final: prev:
let
  # Plugin metadata must cover these IDEs' exact pname/version pairs
  # Keep flake-modules/users/flake.lock's nix-jetbrains-plugins pin in sync
  # with the root nixpkgs input used by this package set
  pkgs = final.unstable;

  /**
    Use the vendor's patched Apple Silicon IDE while Nixpkgs is held back
    by Linux-only dependencies

    # Inputs

    `ide`
    : JetBrains IDE derivation from Nixpkgs

    `pin`
    : Vendor URL, SHA-256 hash, and Marketplace build number

    # Type
    ```
    patchedDarwinIde :: Derivation -> { url :: String; hash :: String; buildNumber :: String; } -> Derivation
    ```

    # Examples
    :::{.example}
    ## Leave Linux packages unchanged

    ```nix
    patchedDarwinIde pkgs.jetbrains.clion clionPin
    => pkgs.jetbrains.clion # on Linux
    ```
    :::
  */
  patchedDarwinIde =
    ide:
    {
      url,
      hash,
      buildNumber,
    }:
    let
      version = "2026.3.0.1";
    in
    if
      pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
      && pkgs.lib.strings.versionOlder ide.version version
    then
      ide.overrideAttrs (old: {
        inherit version;
        src = pkgs.fetchurl { inherit url hash; };
        passthru = old.passthru // {
          inherit buildNumber;
        };
        # This release fixes CVE-2026-111497. Keep any other advisories
        meta = old.meta // {
          knownVulnerabilities = pkgs.lib.lists.filter (
            advisory: !pkgs.lib.strings.hasPrefix "CVE-2026-111497;" advisory
          ) (old.meta.knownVulnerabilities or [ ]);
        };
      })
    else
      ide;

  linuxVmOptions = pkgs.writeText "jetbrains-extra.vmoptions" ''
    -Dawt.toolkit.name=WLToolkit
    -Dsun.awt.wl.WindowDecorationStyle=server
    -Dsun.java2d.vulkan=true
  '';

  commonPlugins = [
    "com.fapiko.jetbrains.plugins.better_direnv" # better-direnv
    "com.github.catppuccin.jetbrains_icons" # Catppuccin Icons
    "com.github.catppuccin.jetbrains" # Catppuccin Theme
    "net.seesharpsoft.intellij.plugins.csv" # CSV Editor
    "com.jetbrains.plugins.ini4idea" # INI
    "nix-idea" # NixIDEA
    "izhangzhihao.rainbow.brackets" # Rainbow Brackets
    "mobi.hsz.idea.gitignore" # .ignore templates and editing
    "ru.adelf.idea.dotenv" # .env language support
    "com.intellij.ideolog" # Log highlighting, filtering, and navigation
  ];

  /**
    Add common and requested plugins to an IDE, then apply platform launcher
    fixes. Plugin metadata must cover the IDE's exact version

    # Inputs
    `ide`: JetBrains package from the selected unstable package set
    `options`: `bundledPlugins` (`[String]`, default `[]`) excludes common
    plugins shipped with the IDE. `extraPlugins` (`[String]`, default `[]`)
    adds plugins after that exclusion
    `extraPluginPackages` (`[Derivation]`, default `[]`) supplies plugins that
    are not in the catalog

    # Type
    ```
    withPlugins :: Derivation -> { bundledPlugins ? []; extraPlugins ? []; extraPluginPackages ? []; } -> Derivation
    ```

    # Examples
    :::{.example}
    ## `withPlugins` usage example
    ```nix
    (withPlugins pkgs.jetbrains.idea { }).meta.mainProgram
    => pkgs.jetbrains.idea.meta.mainProgram
    ```
    :::
  */
  withPlugins =
    ide:
    {
      bundledPlugins ? [ ],
      extraPlugins ? [ ],
      extraPluginPackages ? [ ],
    }:
    let
      plugins = jetbrainsPlugins.lib.pluginsForIdeWith {
        extraOverrides."com.redhat.devtools.lsp4ij" =
          plugin:
          plugin.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.unzip ];
            # LSP4IJ otherwise extracts these resources into the read-only store at startup
            postInstall = (old.postInstall or "") + ''
              bundle="$out/bundles/${old.version}"
              jar="$out/lib/lsp4ij-${old.version}.jar"
              mkdir -p "$bundle/syntaxes"
              unzip -p "$jar" textmate/package.json > "$bundle/package.json"
              unzip -p "$jar" textmate/syntaxes/disassembly.json \
                > "$bundle/syntaxes/disassembly.json"
            '';
          });
        extraOverrides."dev.j-a.swift" =
          plugin:
          plugin.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
              pkgs.unzip
              pkgs.zip
            ];
            # Noctule's RPC providers need an explicit dependency for module classloader visibility.
            postInstall = (old.postInstall or "") + ''
              for module in noctule.core.backend noctule.core.tooling.backend; do
                jar="$out/lib/modules/$module.jar"
                unzip -p "$jar" "$module.xml" > "$module.xml"
                substituteInPlace "$module.xml" --replace-fail '<dependencies>' \
                  '<dependencies><module name="intellij.platform.rpc.backend"/>'
                touch -r "$jar" "$module.xml"
                zip -q -X "$jar" "$module.xml"
                rm "$module.xml"
              done
            '';
          });
      } pkgs ide (pkgs.lib.lists.subtractLists bundledPlugins commonPlugins ++ extraPlugins);
      pluginPackages = pkgs.lib.attrsets.attrValues plugins ++ extraPluginPackages;
    in
    (pkgs.jetbrains.plugins.addPlugins ide pluginPackages).overrideAttrs (
      oldAttrs:
      pkgs.lib.attrsets.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
        let
          launcherName = pkgs.lib.strings.toLower ide.vmoptsIDE;
          vmOptionsName =
            launcherName + pkgs.lib.strings.optionalString pkgs.stdenv.hostPlatform.is64bit "64";
          vmOptions = pkgs.concatText "${launcherName}.vmoptions" [
            "${ide}/${ide.meta.mainProgram}/bin/${vmOptionsName}.vmoptions"
            linuxVmOptions
          ];
        in
        {
          buildPhase = oldAttrs.buildPhase + ''
            for launcher in "$out/${ide.meta.mainProgram}/bin/${launcherName}" \
              "$out/${ide.meta.mainProgram}/bin/${launcherName}.sh"; do
              if [ -f "$launcher" ]; then
                wrapProgram "$launcher" --set ${ide.vmoptsIDE}_VM_OPTIONS ${vmOptions}
              fi
            done
          '';
        }
      )
      // pkgs.lib.attrsets.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        buildPhase = oldAttrs.buildPhase + ''
          substituteInPlace "$out/bin/${ide.meta.mainProgram}" \
            --replace-quiet ${pkgs.lib.strings.escapeShellArg (toString ide)} "$out"
        '';
      }
    );

  riderPackage = patchedDarwinIde pkgs.jetbrains.rider {
    url = "https://download.jetbrains.com/rider/JetBrains.Rider-2026.3.0.1-aarch64.dmg";
    hash = "sha256-FuwW/Baiy68yECCGrffyYYJXTYHr7W38d1rDdnyo5as=";
    buildNumber = "263.7307.325";
  };

  clionPackage = patchedDarwinIde pkgs.jetbrains.clion {
    url = "https://download.jetbrains.com/cpp/CLion-2026.3.0.1-aarch64.dmg";
    hash = "sha256-jOR18nE85zAtxdpYOqekF0kmBaFJKLBvmTmxKKktNBU=";
    buildNumber = "263.7307.257";
  };
in
{
  jetbrains = prev.jetbrains // {
    rider = withPlugins riderPackage {
      bundledPlugins = [ "com.jetbrains.plugins.ini4idea" ];
      extraPlugins = [
        "org.toml.lang"
        "PythonCore"
      ];
    };

    clion = withPlugins clionPackage {
      bundledPlugins = [ "com.jetbrains.plugins.ini4idea" ];
      extraPlugins = [
        "artsiomch.cmake"
        "artsiomch.cmake.plus"
        "com.falsepattern.zigbrains"
        "com.redhat.devtools.lsp4ij"
      ];
    };

    idea = withPlugins pkgs.jetbrains.idea {
      extraPluginPackages = pkgs.callPackage ./jetbrains-idea-plugins.nix { };
      extraPlugins = [
        "boo.fox.haskelllsp"
        # Clojure LSP requires GUI bootstrap and breaks IDEA's headless formatter
        "com.github.clojure-lsp"
        "com.laamella.nim"
        "com.perl5"
        "com.redhat.devtools.lsp4ij"
        "com.jetbrains.php"
        "Dart"
        "io.flutter"
        "dev.j-a.swift"
        "org.elixir_lang"
        "org.jetbrains.plugins.ruby"
        "reasonml"
        "com.demonwav.minecraft-dev"
        "org.intellij.scala"
        "org.jetbrains.plugins.go"
        "PythonCore"
        "Pythonid"
      ];
    };
  };
}
