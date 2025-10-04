{ inputs, ... }:
let
  imports = { inherit inputs; };
in
{
  anons-Mac-mini = (import ./flameflag/anon imports).anons-Mac-mini;
  faputa = (import ./bigshaq9999/nanachi imports).faputa;
  unsigned-int8 = (import ./ashuramaruzxc/unsigned-int8 imports).unsigned-int8;
}
