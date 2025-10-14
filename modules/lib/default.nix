{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  _module.args.eulib =
    let
      libArgs = { inherit inputs pkgs config; };
    in
    lib.extend ((import ../../lib) libArgs);
}
