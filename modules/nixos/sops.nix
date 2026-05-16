{ inputs, lib, ... }:
{
  imports = [ inputs.sops-nix-trivial.nixosModules.sops ];
  sops.age.keyFile = lib.modules.mkDefault "/var/lib/sops/age/keys.txt";
}
