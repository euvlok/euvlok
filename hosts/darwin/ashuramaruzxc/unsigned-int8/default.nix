{
  containerPackage,
  homeModule,
  homebrewModule,
  homebrewTaps,
  sharedModules,
}:
{ lib, ... }:
{
  imports = sharedModules ++ [
    ./brew.nix
    (lib.modules.importApply ./configuration.nix { inherit containerPackage; })
    homeModule
    ./system.nix
    homebrewModule
    { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_shared.yaml; }
    {
      nix-homebrew = {
        enable = true;
        user = "ashuramaru";
        taps = homebrewTaps;
        autoMigrate = true;
      };
    }
  ];
}
