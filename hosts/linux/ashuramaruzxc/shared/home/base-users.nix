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

  home-manager = baseHomeManager.home-manager // {
    users = builtins.mapAttrs (_: extras: baseImports ++ globalImports ++ extras) userImports;
  };
}
