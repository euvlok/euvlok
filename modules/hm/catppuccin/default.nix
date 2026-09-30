{ euvlokInputs }:
{ lib, ... }:
let
  sourceLocks = lib.trivial.importJSON (euvlokInputs.catppuccin + /pkgs/sources.json);
  fetchCatppuccinSource =
    repo:
    let
      lock = sourceLocks.${repo};
    in
    fetchTree {
      type = "github";
      owner = "catppuccin";
      inherit repo;
      inherit (lock) rev;
      narHash = lock.hash;
    };
  paletteSource = fetchCatppuccinSource "palette";
  gituiSource = fetchCatppuccinSource "gitui";
  starshipSource = fetchCatppuccinSource "starship";
in
{

  imports = [
    (import ../../../slop.nix).homeManager.catppuccin
    (lib.modules.importApply ./firefox.nix { inherit paletteSource; })
    ./zen-browser.nix
  ];

  # These integrations read theme files during evaluation. Substitute
  # evaluator-native sources for catppuccin/nix's fetchFromGitHub derivations.
  catppuccin.sources = {
    gitui = lib.modules.mkDefault "${gituiSource}/themes";
    palette = lib.modules.mkDefault paletteSource;
    starship = lib.modules.mkDefault "${starshipSource}/themes";
  };
}
