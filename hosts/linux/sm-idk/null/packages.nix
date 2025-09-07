{
  pkgs,
  ...
}:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      gamemode
      bottles
      rpcs3
      signal-desktop
      equicord
      ;
  };
}
