{ inputs, euvlok, ... }:
let
  nixos-raspberrypi = inputs.nixos-raspberrypi-ashuramaruzxc;
  inherit (inputs.nixos-raspberrypi-ashuramaruzxc.nixosModules) raspberry-pi-5;
in
{
  unsigned-int16 = inputs.nixos-raspberrypi-ashuramaruzxc.lib.nixosSystem {
    specialArgs = { inherit inputs nixos-raspberrypi euvlok; };
    modules = [
      ./configuration.nix
      ./home.nix
      raspberry-pi-5.base
      raspberry-pi-5.display-vc4
      raspberry-pi-5.bluetooth
      inputs.disko-rpi.nixosModules.disko
      inputs.sops-nix-trivial.nixosModules.sops
      # {
      #   sops = {
      #     age.keyFile = "/var/lib/sops/age/keys.txt";
      #     defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int16.yaml;
      #   };
      # }
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "mocha";
          accent = "flamingo";
        };
      }
      ../../../../modules/nixos
      ../../../../modules/cross
      {
        nixos.gnome.enable = true;
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
