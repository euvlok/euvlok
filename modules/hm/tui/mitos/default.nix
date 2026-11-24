{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.euvlok.home.mitos;
  toml = pkgs.formats.toml { };
in
{
  imports = [
    ./languages.nix
    ./settings.nix
  ];

  options.euvlok.home.mitos = {
    enable = lib.options.mkEnableOption "MitOS";
    package = lib.options.mkPackageOption pkgs "mitos" { };
    defaultEditor = lib.options.mkEnableOption "MitOS as the default editor";
    settings = lib.options.mkOption {
      type = toml.type;
      default = { };
      description = "MitOS configuration written to mitos/config.toml.";
    };
    languages = lib.options.mkOption {
      type = toml.type;
      default = { };
      description = "MitOS language configuration written to mitos/languages.toml.";
    };
  };

  config = lib.modules.mkIf cfg.enable {
    euvlok.home.mitos.settings.theme = lib.modules.mkIf (config.catppuccin.autoEnable or false) (
      lib.modules.mkDefault "catppuccin_${config.catppuccin.flavor}"
    );

    home = {
      packages = [
        (pkgs.symlinkJoin {
          name = "${cfg.package.name}-wrapped";
          paths = [ cfg.package ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild =
            let
              tools = lib.attrsets.attrValues {
                inherit (pkgs.unstable)
                  bash-language-server
                  nil
                  nixfmt
                  rumdl
                  shfmt
                  taplo
                  yaml-language-server
                  ;
              };
            in
            ''
              wrapProgram "$out/bin/ms" \
                --suffix PATH : ${lib.strings.makeBinPath tools} \
                --set-default MITOS_CONFIG_DIR ${lib.strings.escapeShellArg "${config.xdg.configHome}/mitos"}
            '';
        })
      ];
      sessionVariables = lib.modules.mkIf cfg.defaultEditor {
        EDITOR = "ms";
        VISUAL = "ms";
      };
      shellAliases = {
        helix = "ms";
        hx = "ms";
        vi = "ms";
        vim = "ms";
      };
    };

    xdg.configFile = {
      "mitos/config.toml".source = toml.generate "mitos-config.toml" cfg.settings;
      "mitos/languages.toml".source = toml.generate "mitos-languages.toml" cfg.languages;
    };
  };
}
