{ isDarwin }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.euvlok.nix.buildParallelism;
  settings = {
    cores = lib.modules.mkIf (cfg.cores != 0) (lib.modules.mkDefault cfg.cores);
    max-jobs = lib.modules.mkIf (cfg.maxJobs != "auto") (lib.modules.mkDefault cfg.maxJobs);
  };
in
{

  options.euvlok.nix.buildParallelism = {
    maxJobs = lib.options.mkOption {
      type = lib.types.either lib.types.ints.positive (lib.types.enum [ "auto" ]);
      default = "auto";
      description = "Maximum number of builds Nix may execute concurrently; auto preserves Determinate's managed default.";
    };

    cores = lib.options.mkOption {
      type = lib.types.ints.unsigned;
      default = 0;
      description = "CPU cores available to each build; zero leaves Nix's all-cores default unchanged.";
    };
  };

  config =
    if isDarwin then { determinateNix.customSettings = settings; } else { nix.settings = settings; };
}
