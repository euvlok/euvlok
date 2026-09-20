{ config, lib, ... }:
let
  cfg = config.euvlok.nixos.networking;
in
{
  options.euvlok.nixos.networking = {
    enable = lib.options.mkEnableOption "NetworkManager" // {
      default = true;
    };

    ethernet.enable = lib.options.mkEnableOption "the shared automatic Ethernet profile" // {
      default = true;
    };

    ethernetBond.enable =
      lib.options.mkEnableOption "enslaving the shared Ethernet profile to bond0"
      // {
        default = false;
      };
  };

  config = lib.modules.mkMerge [
    (lib.modules.mkIf cfg.enable {
      networking.networkmanager.enable = true;
    })

    (lib.modules.mkIf (cfg.enable && cfg.ethernet.enable) {
      networking.networkmanager.ensureProfiles.profiles.ethernet = {
        connection = {
          id = "ethernet";
          type = "ethernet";
        }
        // lib.attrsets.optionalAttrs cfg.ethernetBond.enable {
          master = "bond0";
          slave-type = "bond";
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    })

    {
      assertions = [
        {
          assertion = !cfg.ethernetBond.enable || (cfg.enable && cfg.ethernet.enable);
          message = ''
            euvlok.nixos.networking.ethernetBond.enable requires both
            euvlok.nixos.networking.enable and euvlok.nixos.networking.ethernet.enable.
          '';
        }
      ];
    }
  ];
}
