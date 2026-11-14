{ jetbrainsPlugins }:
final: prev:
let
  # Plugin metadata must cover these IDEs' exact pname/version pairs
  # Keep flake-modules/users/flake.lock's nix-jetbrains-plugins pin in sync
  # with the root nixpkgs-unstable-small input used by this package set
  pkgs = final.unstable;

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

  withPlugins =
    ide:
    {
      bundledPlugins ? [ ],
      extraPlugins ? [ ],
    }:
    let
      plugins = jetbrainsPlugins.lib.pluginsForIdeWith {
        extraOverrides."com.cppcxy.Intellij-EmmyLua" =
          plugin:
          plugin.overrideAttrs (old: {
            # The plugin cannot chmod its bundled servers after they enter the Nix store.
            postInstall = (old.postInstall or "") + ''
              chmod +x "$out"/server/*/emmylua_ls
            '';
          });
        extraOverrides."com.redhat.devtools.lsp4ij" =
          plugin:
          plugin.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.unzip ];
            # LSP4IJ otherwise extracts these resources into the read-only store at startup.
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
    in
    (pkgs.jetbrains.plugins.addPlugins ide (builtins.attrValues plugins)).overrideAttrs (
      oldAttrs:
      pkgs.lib.attrsets.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
        let
          launcherName = pkgs.lib.strings.toLower ide.vmoptsIDE;
          vmOptionsName = launcherName + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.is64bit "64";
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
in
{
  jetbrains = prev.jetbrains // {
    rider = withPlugins pkgs.jetbrains.rider {
      bundledPlugins = [ "com.jetbrains.plugins.ini4idea" ];
      extraPlugins = [
        "org.toml.lang"
        "PythonCore"
      ];
    };

    clion = withPlugins pkgs.jetbrains.clion {
      bundledPlugins = [ "com.jetbrains.plugins.ini4idea" ];
      extraPlugins = [
        "artsiomch.cmake"
        "artsiomch.cmake.plus"
        "com.falsepattern.zigbrains"
        "com.redhat.devtools.lsp4ij"
      ];
    };

    idea = withPlugins pkgs.jetbrains.idea {
      extraPlugins = [
        "boo.fox.haskelllsp"
        "com.cppcxy.Intellij-EmmyLua"
        # Clojure LSP requires GUI bootstrap and breaks IDEA's headless formatter.
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
        "com.intellij.nativeDebug"
        "com.jetbrains.rust"
        "org.intellij.scala"
        "org.jetbrains.plugins.go"
        "PythonCore"
        "Pythonid"
      ];
    };
  };
}
