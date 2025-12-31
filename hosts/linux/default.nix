{ inputs, ... }:
let
  imports = { inherit inputs; };
in
{
  blind-faith = (import ./lay-by/hushh imports).blind-faith;
  nanachi = (import ./bigshaq9999/nanachi imports).nanachi;
  nyx = (import ./flameflag/nyx imports).nyx;
  unsigned-int16 = (import ./ashuramaruzxc/unsigned-int16 imports).unsigned-int16;
  unsigned-int32 = (import ./ashuramaruzxc/unsigned-int32 imports).unsigned-int32;
  unsigned-int64 = (import ./ashuramaruzxc/unsigned-int64 imports).unsigned-int64;
  "null" = (import ./sm-idk/null imports).null;
}
