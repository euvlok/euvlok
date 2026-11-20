{ lib, pkgs, ... }:
{
  services.kanata = {
    enable = true;
    package = pkgs.kanata-with-cmd;
    keyboards.main = {
      devices = [ ];
      extraDefCfg = "danger-enable-cmd yes process-unmapped-keys yes";
      config = lib.trivial.readFile ./config.scm;
    };
  };
}
