{ euvlokInputs }:
{ lib, ... }:
let
  sourceLocks = lib.trivial.importJSON (euvlokInputs.catppuccin + /pkgs/sources.json);
  /**
    Fetch a Catppuccin repository at the revision pinned by the Catppuccin input

    # Inputs

    `repo`
    : Repository name present in Catppuccin's source lock

    # Type
    ```
    fetchCatppuccinSource :: String -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `fetchCatppuccinSource` usage example
    ```nix
    (fetchCatppuccinSource "limine").rev
    => sourceLocks.limine.rev
    ```
    :::
  */
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
  limineSource = fetchCatppuccinSource "limine";
in
{

  # Both upstream integrations read generated package outputs during module
  # evaluation. Their repositories already contain the same data, so keep the
  # upstream option logic and replace only the derivation-backed sources.
  catppuccin.sources = {
    limine = lib.modules.mkDefault "${limineSource}/themes";
    palette = lib.modules.mkDefault (fetchCatppuccinSource "palette");
  };
}
