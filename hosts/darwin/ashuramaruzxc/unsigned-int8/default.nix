{
  containerPackage,
  homeModule,
  homebrewSource,
  homebrewTaps,
  sharedModules,
}:
{ lib, ... }:
{
  imports = sharedModules ++ [
    (lib.modules.importApply ./brew.nix { inherit homebrewTaps; })
    (lib.modules.importApply ./configuration.nix { inherit containerPackage; })
    homeModule
    ./system.nix
    (lib.modules.importApply ../../../../modules/darwin/homebrew-install.nix {
      inherit homebrewSource homebrewTaps;
    })
    { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_shared.yaml; }
  ];
}
