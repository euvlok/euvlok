{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs.kdePackages) kdenlive;
    # Graphics & Design
    inherit (pkgs)
      blender # 3D creation suite
      godot # Game engine
      krita # Digital painting
      ansel # RAW image viewer
      ;
    inkscape = pkgs.inkscape-with-extensions.override {
      inkscapeExtensions = builtins.attrValues {
        inherit (pkgs.inkscape-extensions) textext silhouette;
      };
    };
    # Photoshop but worse
    gimp = pkgs.gimp3-with-plugins.override {
      plugins = builtins.attrValues { inherit (pkgs.gimp3Plugins) gmic; };
    };
  };
  # Streaming and recording
  programs.obs-studio = {
    enable = true;
    package = pkgs.obs-studio;
    plugins = builtins.attrValues { inherit (pkgs.obs-studio-plugins) obs-teleport obs-vkcapture; };
  };
}
