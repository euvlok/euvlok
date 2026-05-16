{ inputs, lib, ... }:
{
  imports = [ inputs.sops-nix-trivial.darwinModules.sops ];
  sops = {
    age.keyFile = lib.modules.mkDefault "/var/lib/sops/age/keys.txt";
    age.sshKeyPaths = lib.modules.mkDefault [ ];
  };
}
