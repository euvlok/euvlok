{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  name = "euvlok development shell";

  languages = {
    nix.enable = true;
    shell.enable = true;
  };

  packages =
    lib.attrsets.attrValues {
      inherit (pkgs)
        flamegraph
        git
        hyperfine
        jujutsu
        jq
        nix-index
        time
        ;
    }
    # The pinned prefetch tool is for maintenance, not the development checks
    ++ lib.lists.optional (!config.devenv.isTesting) (
      pkgs.nix-prefetch-github.override {
        nix = inputs.determinate.inputs.nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      }
    );

  git-hooks = {
    excludes = [ ".devenv" ];
    hooks = import ./devenv/git-hooks.nix { inherit lib pkgs; };
  };

  # Run checks on the submitted files instead of formatting them first
  tasks."devenv:treefmt:run".before = lib.modules.mkIf config.devenv.isTesting (
    lib.modules.mkForce [ ]
  );

  treefmt = {
    enable = true;
    config.programs.nixfmt.enable = true;
  };
}
