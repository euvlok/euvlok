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
    (jetbrainsPlugins.lib.buildIdeWithPlugins pkgs ide (
      pkgs.lib.lists.subtractLists bundledPlugins commonPlugins ++ extraPlugins
    )).overrideAttrs
      (
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
      ];
    };

    idea = withPlugins pkgs.jetbrains.idea {
      extraPlugins = [
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
