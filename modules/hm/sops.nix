{ euvlokInputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ euvlokInputs.sops-nix.homeManagerModules.sops ];
  sops.age.keyFile = lib.modules.mkDefault (
    if pkgs.stdenvNoCC.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt"
    else
      "${config.home.homeDirectory}/.config/sops/age/keys.txt"
  );
}
