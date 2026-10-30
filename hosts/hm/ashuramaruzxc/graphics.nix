{ lib, pkgs, ... }:
{
  home.packages = lib.attrsets.attrValues {
    # Graphics & Design
    inherit (pkgs)
      krita
      blender # 3D creation suite
      godot # Game engine
      ansel # RAW image viewer
      gimp3 # photoshop but worse
      ;
    inherit (pkgs.kdePackages) kdenlive;
    inkscape = pkgs.inkscape-with-extensions.override {
      inkscapeExtensions = lib.attrsets.attrValues {
        inherit (pkgs.inkscape-extensions) textext silhouette;
      };
    };
  };
  # Streaming and recording
  programs.obs-studio = {
    enable = true;
    package = pkgs.obs-studio;
    plugins = lib.attrsets.attrValues { inherit (pkgs.obs-studio-plugins) obs-teleport obs-vkcapture; };
  };
}
