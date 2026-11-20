{
  fetchurl,
  lib,
  stdenv,
  ...
}:

let
  defaultFetchurl = fetchurl;
  defaultStdenv = stdenv;

  /**
    Package a pinned Firefox XPI under its add-on ID for Firefox to discover,
    and expose the same ID and fetched source for policy generation

    Supply either `url` or `urls` so the fetcher has a source for the XPI

    # Inputs

    `options` (attribute set)

    : `stdenv` (optional, default: the library's `stdenv`)
      : Standard environment that builds the output

      `fetchurl` (optional, default: the library's `fetchurl`)
      : Fetcher for the pinned XPI

      `pname` (required)
      : Base name for the output derivation

      `version` (required)
      : Version of the XPI

      `addonId` (required)
      : Firefox extension ID, which must be safe as a filename stem

      `url` (optional, default: `""`)
      : URL of the XPI when using a single source

      `urls` (optional, default: `[ ]`)
      : Alternative to `url`, listing sources to try in order

      `sha256` (required)
      : SHA-256 hash accepted by `fetchurl`

      `meta` (required)
      : Package metadata passed through unchanged

    # Type

    ```
    buildFirefoxXpiAddon :: {
      stdenv :: AttrSet ? defaultStdenv;
      fetchurl :: (AttrSet -> Derivation) ? defaultFetchurl;
      pname :: String;
      version :: String;
      addonId :: String;
      url :: String ? "";
      urls :: [String] ? [];
      sha256 :: String;
      meta :: AttrSet;
      ...
    } -> Derivation
    ```

    # Examples
    :::{.example}
    ## Expose the ID of a pinned add-on

    ```nix
    (buildFirefoxXpiAddon {
      pname = "catppuccin-web-file-icons";
      version = "1.6.1";
      addonId = "{bbb880ce-43c9-47ae-b746-c3e0096c5b76}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4647055/catppuccin_web_file_icons-1.6.1.xpi";
      sha256 = "sha256-oe4jEr0ssTBqON7EtQ7cVaQ5edgYczJk3ulVxsBKdnY=";
      meta = { };
    }).addonId
    => "{bbb880ce-43c9-47ae-b746-c3e0096c5b76}"
    ```

    :::
  */
  buildFirefoxXpiAddon = lib.customisation.makeOverridable (
    {
      stdenv ? defaultStdenv,
      fetchurl ? defaultFetchurl,
      pname,
      version,
      addonId,
      url ? "",
      urls ? [ ],
      sha256,
      meta,
      ...
    }:
    stdenv.mkDerivation (finalAttrs: {
      name = "${pname}-${version}";

      inherit meta;

      src = fetchurl { inherit url urls sha256; };

      preferLocalBuild = true;
      allowSubstitutes = true;

      passthru = {
        inherit addonId;
      };

      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" \
          "$dst/"${lib.strings.escapeShellArg "${finalAttrs.passthru.addonId}.xpi"}
      '';
    })
  );
in
{
  inherit buildFirefoxXpiAddon;

  /**
    Create a Tweezle extension policy that installs the pinned XPI from the
    Nix store and disables updates outside Nix

    # Inputs

    `addon`

    : Add-on derivation with an `addonId` and a fetched `src` XPI, as returned
      by `buildFirefoxXpiAddon`

    # Type

    ```
    toTweezleExtension :: { addonId :: String; src :: Derivation; ... } -> AttrSet
    ```

    # Examples
    :::{.example}
    ## Convert an add-on built by `buildFirefoxXpiAddon`

    ```nix
    (toTweezleExtension addon).installation_mode
    => "normal_installed"
    ```

    :::
  */
  toTweezleExtension = addon: {
    id = addon.addonId;
    # Escape path components without turning directory separators into %2F
    install_url = "file://${
      lib.strings.concatMapStringsSep "/" lib.strings.escapeURL (
        lib.strings.splitString "/" (toString addon.src)
      )
    }";
    installation_mode = "normal_installed";
    updates_disabled = true;
  };
}
