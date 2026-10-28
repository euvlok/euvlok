{ applyEuvlokInputs, euvlokInputs }:
{
  default = applyEuvlokInputs ../../modules/darwin;
  apple-intelligence = (import ../../slop.nix).darwin { inherit euvlokInputs; };
  home-manager = applyEuvlokInputs ../../modules/darwin/home-manager.nix;
  nix = ../../modules/darwin/nix.nix;
  sops = applyEuvlokInputs ../../modules/darwin/sops.nix;
  system = ../../modules/darwin/system.nix;
  zsh = ../../modules/darwin/zsh.nix;
}
