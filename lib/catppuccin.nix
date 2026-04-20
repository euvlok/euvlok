{
  /**
    # Type: { flavor: String, accent: String } -> AttrSet

    Builds a module attrset enabling catppuccin with the given flavor and accent.

    # Example

    ```nix
    mkCatppuccin { flavor = "frappe"; accent = "blue"; }
    # => { catppuccin = { enable = true; flavor = "frappe"; accent = "blue"; }; }
    ```
  */
  mkCatppuccin =
    { flavor, accent }:
    {
      catppuccin = {
        enable = true;
        inherit flavor accent;
      };
    };

  # Canonical catppuccin theme per host. Keys match attribute names in
  # {nixos,darwin}Configurations. Hosts with the same short name on
  # different platforms are suffixed with -linux / -darwin.
  hosts = {
    unsigned-int8 = {
      flavor = "mocha";
      accent = "flamingo";
    };
    unsigned-int16 = {
      flavor = "mocha";
      accent = "flamingo";
    };
    unsigned-int32 = {
      flavor = "mocha";
      accent = "flamingo";
    };
    unsigned-int64 = {
      flavor = "mocha";
      accent = "rosewater";
    };
    nyx = {
      flavor = "frappe";
      accent = "blue";
    };
    nanachi-linux = {
      flavor = "frappe";
      accent = "blue";
    };
    nanachi-darwin = {
      flavor = "frappe";
      accent = "rosewater";
    };
    FlameFlags-Mac-mini = {
      flavor = "frappe";
      accent = "blue";
    };
  };
}
