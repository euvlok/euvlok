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
  #   imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];
  #   home-manager = {
  #     useGlobalPkgs = true;
  #     useUserPackages = true;
  #     backupFileExtension = "bak";
  #     extraSpecialArgs = { inherit inputs eulib; };
  #   };
  # };

  home-manager = baseHomeManager.home-manager // {
    users = builtins.mapAttrs (_: extras: baseImports ++ globalImports ++ extras) userImports;
  };
}
