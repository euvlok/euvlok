{
  baseImports,
  baseHomeManager,
}:
{
  userImports,
  globalImports ? [ ],
}:
{
  inherit (baseHomeManager) imports;

  # baseHomeManager = {
  #   imports = [ inputs.home-manager.nixosModules.home-manager ];
  #   home-manager = {
  #     useUserPackages = true;
  #     backupFileExtension = "bak";
  #     extraSpecialArgs = { inherit inputs eulib; };
  #   };
  # };

  home-manager = baseHomeManager.home-manager // {
    users = builtins.mapAttrs (_: extras: {
      imports = baseImports ++ globalImports ++ extras;
    }) userImports;
  };
}
