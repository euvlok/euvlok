{ inputs, ... }:
let
  nixos-raspberrypi = inputs.nixos-raspberrypi-ashuramaruzxc;
  inherit (inputs.nixos-raspberrypi-ashuramaruzxc.nixosModules) raspberry-pi-5 usb-gadget-ethernet;
in
{
  unsigned-int16 = inputs.nixos-raspberrypi-ashuramaruzxc.lib.nixosSystem {
    specialArgs = { inherit inputs nixos-raspberrypi; };
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
      inputs.disko-rpi.nixosModules.disko
    ]
    ++ [
      usb-gadget-ethernet
      raspberry-pi-5.base
      raspberry-pi-5.display-vc4
      raspberry-pi-5.bluetooth
    ]
    ++ [
      inputs.sops-nix-trivial.nixosModules.sops
      {
        sops = {
          age.keyFile = "/var/lib/sops/age/keys.txt";
          defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int16.yaml;
        };
      }
    ]
    ++ [
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "mocha";
          accent = "flamingo";
        };
      }
    ]
    ++ [
      inputs.flatpak-declerative-trivial.nixosModule
      {
        services.flatpak = {
          enable = true;
          remotes = {
            "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
          };
        };
      }
    ]
    ++ [
      inputs.self.crossModules.default
      {
        nixos = {
          plasma.enable = true;
          gnome.enable = true;
        };
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
