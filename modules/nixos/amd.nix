{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.euvlok.nixos.amd.enable = lib.options.mkEnableOption "AMD drivers";

  config = lib.modules.mkMerge [
    (lib.modules.mkIf config.euvlok.nixos.amd.enable {
      nixpkgs.config.rocmSupport = true;
      environment.systemPackages = [ pkgs.clinfo ];
      hardware.amdgpu.opencl.enable = true;
      services.lact.enable = true;
      systemd.tmpfiles.settings.rocm =
        let
          rocmEnv = pkgs.symlinkJoin {
            name = "rocm-combined";
            paths = lib.attrsets.attrValues {
              inherit (pkgs.rocmPackages) rocblas hipblas clr;
            };
          };
        in
        {
          "/opt/rocm"."L+".argument = toString rocmEnv;
        };
    })
  ];
}
