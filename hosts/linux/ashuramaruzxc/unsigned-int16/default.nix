inputs:
let
  inherit (inputs.nixos-raspberrypi.nixosModules) raspberry-pi-5 usb-gadget-ethernet;
  inherit (import ../../../../lib/catppuccin.nix) mkCatppuccin hosts;
in
inputs.nixos-raspberrypi.lib.nixosSystem {
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
    { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int16.yaml; }
    (mkCatppuccin hosts.unsigned-int16)
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
}
