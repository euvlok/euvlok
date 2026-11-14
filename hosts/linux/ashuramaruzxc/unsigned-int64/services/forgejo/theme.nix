{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.forgejo;
  version = "1.5.0";
  releaseUrl = "https://github.com/whereareiam/forgejo-github-theme/releases/download/${version}";
  stylesheets = pkgs.fetchurl {
    url = "${releaseUrl}/theme-github-base.tar.gz";
    hash = "sha256-FEBKfUOOEHHC9IOb+97G9UuCwVVrpDgWl+tOTRkzlZQ=";
  };
  accessibility = pkgs.fetchurl {
    url = "${releaseUrl}/theme-github-accessibility.tar.gz";
    hash = "sha256-y6xorEqHdSw8dRs3bZ4D3dVu7GSkfWMHhNfSt+Cll+w=";
  };
  extras = pkgs.fetchurl {
    url = "${releaseUrl}/theme-github-extras.tar.gz";
    hash = "sha256-QUR2CJ74xWFIlOlzl3gPUfg8wdc7hjp4z12CsKqS14w=";
  };
  templates = pkgs.fetchurl {
    url = "${releaseUrl}/theme-github-templates.tar.gz";
    hash = "sha256-uZk2HHwfPHpe790bqid0hvF3Lcy6XTGKNKOEMw1Q2lc=";
  };
  theme =
    pkgs.runCommand "forgejo-github-theme-${version}"
      {
        nativeBuildInputs = [
          pkgs.gnutar
          pkgs.gzip
        ];
      }
      ''
        mkdir -p "$out/public/assets/css"
        tar -xzf ${stylesheets} -C "$out/public/assets/css"
        tar -xzf ${accessibility} -C "$out/public/assets/css"
        tar -xzf ${extras} -C "$out/public/assets/css"
        tar -xzf ${templates} -C "$out"
      '';
in
{
  assertions = [
    {
      assertion = lib.versions.major cfg.package.version == "17";
      message = "Forgejo GitHub theme ${version} requires Forgejo 17; update the theme and its templates before changing the server major version.";
    }
  ];

  catppuccin.forgejo.enable = false;

  services.forgejo.settings.ui = {
    DEFAULT_THEME = "github-auto";
    THEMES = lib.concatStringsSep "," [
      "forgejo-auto"
      "forgejo-light"
      "forgejo-dark"
      "gitea-auto"
      "gitea-light"
      "gitea-dark"
      "forgejo-auto-deuteranopia-protanopia"
      "forgejo-light-deuteranopia-protanopia"
      "forgejo-dark-deuteranopia-protanopia"
      "forgejo-auto-tritanopia"
      "forgejo-light-tritanopia"
      "forgejo-dark-tritanopia"
      "github-auto"
      "github-light"
      "github-dark"
      "github-soft-dark"
      "github-colorblind-auto"
      "github-colorblind-light"
      "github-colorblind-dark"
      "github-tritanopia-auto"
      "github-tritanopia-light"
      "github-tritanopia-dark"
      "github-high-contrast-auto"
      "github-high-contrast-light"
      "github-high-contrast-dark"
      "github-high-contrast-soft-dark"
      "github-high-contrast-colorblind-auto"
      "github-high-contrast-colorblind-light"
      "github-high-contrast-colorblind-dark"
      "github-high-contrast-tritanopia-auto"
      "github-high-contrast-tritanopia-light"
      "github-high-contrast-tritanopia-dark"
      "github-pink-auto"
      "github-pink-light"
      "github-pink-dark"
      "github-pink-soft-dark"
      "github-gitea-auto"
      "github-gitea-light"
      "github-gitea-dark"
      "github-catppuccin-auto"
      "github-catppuccin-latte"
      "github-catppuccin-frappe"
      "github-catppuccin-macchiato"
      "github-catppuccin-mocha"
    ];
  };

  systemd.services.forgejo = {
    serviceConfig.BindReadOnlyPaths = [
      "${theme}/public:${cfg.customDir}/public"
      "${theme}/templates:${cfg.customDir}/templates"
    ];
    restartTriggers = [ theme ];
  };
}
