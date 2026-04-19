{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ inputs.sops-nix-trivial.homeManagerModules.sops ];
  sops.age.keyFile = lib.mkDefault (
    if pkgs.stdenvNoCC.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt"
    else
      "${config.home.homeDirectory}/.config/sops/age/keys.txt"
  );
}
