{ pkgs }:
{
  action-validator.enable = true;
  actionlint.enable = true;
  deadnix = {
    enable = true;
    excludes = [
      "^hosts/hm/ashuramaruzxc/firefox/extensions\\.nix$"
      "^modules/hm/gui/firefox/extensions\\.nix$"
    ];
    settings.noLambdaPatternNames = true;
  };
  nixfmt-rfc-style = {
    enable = true;
    package = pkgs.nixfmt;
  };
  rumdl = {
    enable = true;
    settings.configuration.global.disable = [
      "MD013"
      "MD033"
    ];
  };
  shellcheck.enable = true;
  statix.enable = true;
  yamllint = {
    enable = true;
    files = "^\\.github/";
  };
  zizmor = {
    enable = true;
    args = [
      "--offline"
      "--persona=pedantic"
    ];
    files = "^\\.github/(actions|workflows)/";
  };
}
