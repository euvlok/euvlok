{ inputs, ... }:
let
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
in
{
  system = {
    keyboard.enableKeyMapping = true;
    defaults.dock.tilesize = 65;
    stateVersion = 5;
  };

  nixpkgs.overlays = [
    add-24_11-packages
    add-unstable-small-packages
  ];
}
