{ inputs, lib, ... }:
{
  imports = [ inputs.sops-nix-trivial.darwinModules.sops ];
  sops = {
    age.keyFile = lib.mkDefault "/var/lib/sops/age/keys.txt";
    age.sshKeyPaths = lib.mkDefault [ ];
  };
}
