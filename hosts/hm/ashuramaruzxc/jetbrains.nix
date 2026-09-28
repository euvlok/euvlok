{ pkgs, jetbrainsPlugins }:
let
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
      pkgs.lib.subtractLists bundledPlugins commonPlugins ++ extraPlugins
    )).overrideAttrs
      (
        oldAttrs:
        pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          # addPlugins rewrites Contents/bin, but the macOS CLI launcher lives in bin.
          # Its buildPhase has no postBuild hook, so append the fix directly.
          buildPhase = oldAttrs.buildPhase + ''
            substituteInPlace "$out/bin/${ide.meta.mainProgram}" \
              --replace-quiet ${pkgs.lib.escapeShellArg (toString ide)} "$out"
          '';
        }
      );
in
{
  rider = withPlugins pkgs.jetbrains.rider {
    bundledPlugins = [ "com.jetbrains.plugins.ini4idea" ];
    extraPlugins = [
      "org.toml.lang" # Required by Python Community Edition; absent from Rider.
      "PythonCore" # Python Community Edition
    ];
  };

  clion = withPlugins pkgs.jetbrains.clion {
    # CLion also bundles Rust, Python Community Edition, and TOML support.
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
      "PythonCore" # Required by the Python plugin.
      "Pythonid"
      "com.jetbrains.rust"
      "org.intellij.scala"
    ];
  };

  datagrip = withPlugins pkgs.jetbrains.datagrip { };
  dataspell = withPlugins pkgs.jetbrains.dataspell { };
}
