{ inputs, euvlok, ... }:
{
  blind-faith = (import ./lay-by/hushh { inherit inputs euvlok; }).blind-faith;
  nanachi = (import ./bigshaq9999/nanachi { inherit inputs euvlok; }).nanachi;
  nyx = (import ./donteatoreo/nyx { inherit inputs euvlok; }).nyx;
  signed-int16 = (import ./2husecondary/signed-int16 { inherit inputs euvlok; }).signed-int16;
  unsigned-int16 = (import ./ashuramaruzxc/unsigned-int16 { inherit inputs euvlok; }).unsigned-int16;
  unsigned-int32 = (import ./ashuramaruzxc/unsigned-int32 { inherit inputs euvlok; }).unsigned-int32;
  unsigned-int64 = (import ./ashuramaruzxc/unsigned-int64 { inherit inputs euvlok; }).unsigned-int64;
}
