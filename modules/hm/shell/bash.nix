{ lib, config, ... }:
let
  paths = import ./paths.nix { inherit lib; };
in
{
  options.hm.bash.enable = lib.mkEnableOption "Bash" // {
    default = true;
  };

  config = lib.mkIf config.hm.bash.enable {
    programs.bash = {
      enable = true;
      enableVteIntegration = true;
      initExtra = ''
        ${paths.hm.shell.binPaths.bash}
      '';
    };
  };
}
