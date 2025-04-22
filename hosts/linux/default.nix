{ inputs, ... }:
{
  blind-faith = (import ./lay-by/hushh { inherit inputs; }).blind-faith;
  nanachi = (import ./bigshaq9999/nanachi { inherit inputs; }).nanachi;
  nyx = (import ./donteatoreo/nyx { inherit inputs; }).nyx;
  unsigned-int32 = (import ./ashuramaruzxc/unsigned-int32 { inherit inputs; }).unsigned-int32;
  unsigned-int64 = (import ./ashuramaruzxc/unsigned-int64 { inherit inputs; }).unsigned-int64;
}
