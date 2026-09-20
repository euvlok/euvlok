{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [ ./extensions.nix ];

  options.euvlok.home.vscode = {
    enable = lib.options.mkEnableOption "VSCode";
    extensionIds = lib.options.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      internal = true;
      description = "VS Code Marketplace extension IDs resolved by nix4vscode.";
    };
  };

  config = lib.modules.mkIf config.euvlok.home.vscode.enable {
    programs.vscode = {
      enable = true;
      package =
        if pkgs.unstable.stdenvNoCC.hostPlatform.isLinux then
          (pkgs.unstable.vscode.override {
            commandLineArgs = "--wayland-text-input-version=3 --enable-wayland-ime";
          })
        else
          pkgs.unstable.vscode;
      profiles.default.extensions = pkgs.euvlokVscodeExtensions {
        version = config.programs.vscode.package.version;
        extensions = lib.lists.unique config.euvlok.home.vscode.extensionIds;
      };
    };
  };
}
