{ applyEuvlokInputs }:
{
  default = applyEuvlokInputs ../../modules/darwin;
  apple-intelligence = applyEuvlokInputs ../../modules/darwin/apple-intelligence.nix;
  nix = ../../modules/darwin/nix.nix;
  sops = applyEuvlokInputs ../../modules/darwin/sops.nix;
  system = ../../modules/darwin/system.nix;
  zsh = ../../modules/darwin/zsh.nix;
}
