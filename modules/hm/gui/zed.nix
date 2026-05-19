{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.hm.zed-editor.enable = lib.options.mkEnableOption "Zed Editor";

  config = lib.modules.mkIf config.hm.zed-editor.enable {
    programs.zed-editor.enable = true;
    programs.zed-editor.extraPackages = builtins.attrValues {
      inherit (pkgs.unstable)
        bash-language-server
        markdownlint-cli2
        nil
        nixfmt
        prettier
        shellcheck
        shfmt
        taplo
        typos-lsp
        vscode-langservers-extracted
        yaml-language-server
        ;
    };
    programs.zed-editor.extensions = [
      "nix"
      "unicode"
      "json5"
      "xml"
      "typos"
      "cspell"
      "biome"
      "env"
      "csv"
      "toml"
      "yaml"
      "ini"
      "beancount"
      "make"
      "cmake"
      "meson"
      "stylelint"
      "http"
      "markdownlint"
    ];

    programs.zed-editor.userSettings = {
      auto_update = false; # Obviously we can't use that...
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      wrap_guides = [
        72
        80
        120
      ];
      file_types."XML" = [
        "*.csproj"
        "*.fsproj"
        "*.props"
        "*.sln"
        "*.slnx"
        "*.targets"
        "*.vbproj"
      ];
    };

    programs.zed-editor.userSettings.languages = {
      "Nix" = {
        language_servers = [ "nil" ];
        formatter = {
          external = {
            command = "nixfmt";
          };
        };
      };
      "YAML" = {
        formatter = "language_server";
      };
      "JSON" = {
        language_servers = [ "json-language-server" ];
        formatter = {
          external = {
            command = "prettier";
            arguments = [
              "--parser"
              "json"
              "--stdin-filepath"
              "{buffer_path}"
            ];
          };
        };
      };
      "HTML" = {
        formatter = {
          external = {
            command = "prettier";
            arguments = [
              "--parser"
              "html"
              "--stdin-filepath"
              "{buffer_path}"
            ];
          };
        };
      };
      "CSS" = {
        formatter = {
          external = {
            command = "prettier";
            arguments = [
              "--parser"
              "css"
              "--stdin-filepath"
              "{buffer_path}"
            ];
          };
        };
      };
      "Bash" = {
        language_servers = [ "bash-language-server" ];
        formatter = {
          external = {
            command = "shfmt";
            arguments = [
              "-i"
              "2"
            ];
          };
        };
      };
      "TOML" = {
        language_servers = [ "taplo" ];
        formatter = "language_server";
      };
      "Markdown" = {
        language_servers = [ "markdownlint" ];
        formatter = {
          external = {
            command = "prettier";
            arguments = [
              "--parser"
              "markdown"
              "--stdin-filepath"
              "{buffer_path}"
            ];
          };
        };
      };
    };

    programs.zed-editor.userSettings.lsp = {
      nil.settings.nil.nix.flake.autoArchive = true;

      "json-language-server".binary = {
        path = "vscode-json-language-server";
        arguments = [ "--stdio" ];
      };

      taplo.binary = {
        path = "taplo";
        arguments = [
          "lsp"
          "stdio"
        ];
      };

      typos.binary.path = "typos-lsp";

      markdownlint.settings.config = {
        MD033 = false;
        MD041 = false;
        MD045 = false;
      };
    };
  };
}
