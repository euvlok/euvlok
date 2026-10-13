{ inputs, pkgs, ... }:
{
  name = "euvlok development shell";

  languages = {
    nix.enable = true;
    shell.enable = true;
  };

  packages = builtins.attrValues {
    inherit (pkgs)
      flamegraph
      git
      hyperfine
      jujutsu
      jq
      nix-index
      time
      ;
    nix-prefetch-github = pkgs.nix-prefetch-github.override {
      nix = inputs.determinate.inputs.nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };

  git-hooks = {
    excludes = [ ".devenv" ];
    hooks = import ./devenv/git-hooks.nix { inherit pkgs; };
  };

  treefmt = {
    enable = true;
    config.programs.nixfmt.enable = true;
  };
}
