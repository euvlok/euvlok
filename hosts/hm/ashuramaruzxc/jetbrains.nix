{ jetbrainsPlugins }:
final: prev:
let
  pkgs = final.unstable;

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
        pkgs.lib.attrsets.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
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
        "PythonCore" # Python Community Edition
      ];
    };

    clion = withPlugins pkgs.jetbrains.clion {
      bundledPlugins = [ "com.jetbrains.plugins.ini4idea" ];
      extraPlugins = [
        "artsiomch.cmake" # CMake Plus requires CMake simple highlighter.
        "artsiomch.cmake.plus"
      ];
    };

    idea = withPlugins pkgs.jetbrains.idea {
      extraPlugins = [
        "org.jetbrains.plugins.go"
        "com.demonwav.minecraft-dev"
        "PythonCore"
        "Pythonid"
        "com.jetbrains.rust"
        "org.intellij.scala"
      ];
    };
  };
}
