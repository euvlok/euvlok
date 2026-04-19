{ inputs, lib, ... }:
{
  imports = [ inputs.sops-nix-trivial.nixosModules.sops ];
  sops.age.keyFile = lib.mkDefault "/var/lib/sops/age/keys.txt";
}
