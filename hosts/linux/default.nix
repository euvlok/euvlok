{ inputs, ... }:
{
  # --- lay-by ---
  blind-faith = (import ./lay-by/hushh { inherit inputs; }).blind-faith;

  # --- bigshaq9999 ---
  nanachi = (import ./bigshaq9999/nanachi { inherit inputs; }).nanachi;

  # --- donteatoreo ---
  nyx = (import ./donteatoreo/nyx { inherit inputs; }).nyx;

  # --- 2husecondary ---
  signed-int16 = (import ./2husecondary/signed-int16 { inherit inputs; }).signed-int16;

  # --- ashuramaruzxc ---
  unsigned-int16 = (import ./ashuramaruzxc/unsigned-int16 { inherit inputs; }).unsigned-int16;
  unsigned-int32 = (import ./ashuramaruzxc/unsigned-int32 { inherit inputs; }).unsigned-int32;
  unsigned-int64 = (import ./ashuramaruzxc/unsigned-int64 { inherit inputs; }).unsigned-int64;
}
