{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      nil
      nixd
      nixfmt-rfc-style
      bash-language-server
      shfmt
      ;
  };

  programs.zed-editor = {
    enable = true;
    package = pkgs.unstable.zed-editor;
    extensions = [
      "nix"
      "xml"
      "cspell"
      "csv"
      "toml"
      "yaml"
      "ini"
      "stylelint"
      "material-icon-theme"
    ];

    userSettings = {
      auto_update = false;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      wrap_guides = [
        72
        80
        120
      ];
      icon_theme = "Material Icon Theme";
      autosave = "on_focus_change";
      disable_ai = true;
      restore_on_startup = "none";
      vim_mode = true;

      lsp.nil.formatting.command = [ "nixfmt" ];

      languages = {
        "Nix" = {
          language_servers = [ "nil" ];
          formatter.external.command = "nixfmt";
        };
        "Bash" = {
          language_servers = [ "bash-language-server" ];
          formatter.external = {
            command = "shfmt";
            arguments = [
              "-i"
              "2"
            ];
          };
        };
      };
    };
  };
}
