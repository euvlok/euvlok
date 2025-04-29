{ inputs, ... }:
let
  add-24_05-packages = final: _: {
    nixpkgs-24_11 = import inputs.nixpkgs-24_05 {
      inherit (final) system config;
    };
  };
  add-24_11-packages = final: _: {
    nixpkgs-24_11 = import inputs.nixpkgs-ashuramaruzxc {
      inherit (final) system config;
    };
  };
  add-unstable-small-packages = final: _: {
    unstable-small = import inputs.nixpkgs-unstable-small {
      inherit (final) system config;
    };
  };
  add-x86_64-darwin-packages = final: _: {
    nixpkgs_x86_64-darwin = import inputs.nixpkgs-donteatoreo {
      system = "x86_64-darwin";
      inherit (final) config;
    };
  };
in
{
  system = {
    keyboard.enableKeyMapping = true;
    defaults.dock.tilesize = 42;
    stateVersion = 5;
  };
  nixpkgs.overlays = [
    add-24_05-packages
    add-24_11-packages
    add-unstable-small-packages
    add-x86_64-darwin-packages
  ];
}
