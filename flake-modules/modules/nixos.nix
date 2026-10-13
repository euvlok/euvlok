{
  applyEuvlokInputs,
  mkDesktopModule,
}:
{
  default = applyEuvlokInputs ../../modules/nixos;
  amd = ../../modules/nixos/amd.nix;
  audio = ../../modules/nixos/audio.nix;
  boot = ../../modules/nixos/boot.nix;
  cosmic = mkDesktopModule ../../modules/nixos/cosmic.nix;
  gnome = mkDesktopModule ../../modules/nixos/gnome.nix;
  hardware = ../../modules/nixos/hardware.nix;
  locale = ../../modules/nixos/locale.nix;
  networking = ../../modules/nixos/networking.nix;
  nix-ld = ../../modules/nixos/nix-ld/nix-ld.nix;
  nix = ../../modules/nixos/nix.nix;
  nvidia = applyEuvlokInputs ../../modules/nixos/nvidia.nix;
  plasma = mkDesktopModule ../../modules/nixos/plasma.nix;
  security = ../../modules/nixos/security.nix;
  services = ../../modules/nixos/services.nix;
  session-variables = mkDesktopModule ../../modules/nixos/sessionVariables.nix;
  sops = applyEuvlokInputs ../../modules/nixos/sops.nix;
  steam = ../../modules/nixos/steam.nix;
  zram = ../../modules/nixos/zram.nix;
}
