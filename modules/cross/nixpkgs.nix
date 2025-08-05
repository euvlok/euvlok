{
  inputs,
  config,
  lib,
  ...
}:
{
  options.cross.nixpkgs = {
    enable = lib.mkEnableOption "Nixpkgs";
    cudaSupport = lib.mkEnableOption "Cuda";
  };

  config = lib.mkIf config.cross.nixpkgs.enable {
    nixpkgs = {
      config = {
        allowUnfree = true;
        inherit (config.cross.nixpkgs) cudaSupport;
      };
      overlays = [
        inputs.nur-trivial.overlays.default
        inputs.nix-vscode-extensions-trivial.overlays.default
        (final: _: { yt-dlp = final.callPackage ../../pkgs/yt-dlp.nix { }; })
      ]
      ++ lib.optionals config.nixos.lix.enable [
        (_: _: {
          lix =
            (inputs.lix-source.packages.${config.nixpkgs.hostPlatform.system}.default.override {
              aws-sdk-cpp = null;
            }).overrideAttrs
              (args: {
                postPatch = (args.postPatch or "") + ''
                  substituteInPlace lix/libmain/shared.cc \
                    --replace-fail "(Lix, like Nix)" "(Lix, like Nix with disabled aws-sdk-cpp)"        
                '';
                doCheck = false;
              });
        })
      ];
    };
  };
}
