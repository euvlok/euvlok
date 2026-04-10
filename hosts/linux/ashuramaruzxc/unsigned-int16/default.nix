{ inputs, ... }:
let
  inherit (inputs.nixos-raspberrypi.nixosModules) raspberry-pi-5 usb-gadget-ethernet;
in
{
  unsigned-int16 = inputs.nixos-raspberrypi.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      nixos-raspberrypi = inputs.nixos-raspberrypi;
    };
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
      inputs.disko-rpi.nixosModules.disko
      usb-gadget-ethernet
      raspberry-pi-5.base
      raspberry-pi-5.bluetooth
      raspberry-pi-5.display-vc4
      raspberry-pi-5.page-size-16k
      inputs.sops-nix-trivial.nixosModules.sops
      {
        sops = {
          age.keyFile = "/var/lib/sops/age/keys.txt";
          defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int16.yaml;
        };
      }
      {
        catppuccin = {
          enable = true;
          accent = "flamingo";
          flavor = "mocha";
        };
      }
      inputs.flatpak-declerative-trivial.nixosModules.default
      {
        services.flatpak = {
          enable = true;
          remotes = {
            "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
          };
        };
      }
      {
        nixos = {
          plasma.enable = true;
          gnome.enable = true;
        };
      }
    ];
  };
}
