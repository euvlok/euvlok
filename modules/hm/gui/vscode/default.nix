{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [ ./extensions.nix ];

  options.hm.vscode.enable = lib.mkEnableOption "VSCode";

  config = lib.mkIf config.hm.vscode.enable {
    programs.vscode = {
      enable = true;
      package =
        if pkgs.unstable.stdenvNoCC.isLinux then
          (pkgs.unstable.vscode.override {
            commandLineArgs = "--wayland-text-input-version=3 --enable-wayland-ime";
          })
        else
          pkgs.unstable.vscode;
    };
  };
}
