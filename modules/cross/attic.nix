{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkMerge
    mkOption
    mkDefault
    types
    ;
in
{
  options.attic = {
    enable = mkEnableOption "Attic binary cache" // {
      default = true;
    };

    baseUrl = mkOption {
      type = types.str;
      default = "https://attic.tenjin-dk.com";
      example = "https://attic.example.com";
      description = ''
        Canonical HTTPS endpoint for the Attic server. This value should not end
        with a slash
      '';
    };

    cacheName = mkOption {
      type = types.str;
      default = "tenjin";
      example = "central";
      description = "Default Attic cache name to pull from";
    };

    cachePublicKey = mkOption {
      type = types.str;
      default = "tenjin:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      description = ''
        Shared Attic cache public key (the `Public Key` line from `attic cache info`).
        When set, every host will trust the Tenjin cache automatically.
      '';
    };

    client = {
      enable = mkEnableOption "configuring Attic as a substituter for nix-daemon";

      substituter = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://attic.example.com/my-cache";
        description = ''
          Fully-qualified URL of the Attic cache to add to `nix.settings.substituters`.
          When unset, it is derived from `attic.baseUrl` and `attic.cacheName`.
        '';
      };

      publicKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "euvlok:WcnO6s4aVkB6CKRaPPpKvHLZykWXASV6c+/Ssg8uQEY=";
        description = ''
          Attic cache public key to include in `nix.settings.trusted-public-keys`
          Keep this in sync with `attic cache info`
        '';
      };
    };
  };

  config = mkMerge [
    ({
      attic.client.enable = mkDefault true;
      attic.client.substituter = mkDefault "${config.attic.baseUrl}/${config.attic.cacheName}";
      attic.client.publicKey = mkDefault config.attic.cachePublicKey;
    })
    (lib.mkIf (config.attic.client.enable) {
      nix.settings = {
        substituters = lib.mkAfter [ config.attic.client.substituter ];
        trusted-public-keys = lib.mkAfter [ config.attic.client.publicKey ];
      };
    })
  ];
}
