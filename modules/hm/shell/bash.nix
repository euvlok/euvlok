{ lib, config, ... }:
let
  paths = import ./paths.nix { inherit lib; };
in
{
  options.hm.bash.enable = lib.options.mkEnableOption "Bash" // {
    default = true;
  };

  config = lib.modules.mkIf config.hm.bash.enable {
    programs.bash = {
      enable = true;
      enableVteIntegration = true;
      initExtra = ''
        ${paths.hm.shell.binPaths.bash}
      '';
    };
  };
}
