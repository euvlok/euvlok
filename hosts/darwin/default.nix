{ inputs, ... }:
let
  imports = { inherit inputs; };
in
{
  FlameFlags-Mac-mini = (import ./flameflag/flame imports).FlameFlags-Mac-mini;
  faputa = (import ./bigshaq9999/nanachi imports).faputa;
  unsigned-int8 = (import ./ashuramaruzxc/unsigned-int8 imports).unsigned-int8;
}
