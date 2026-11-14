{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.euvlok.home.zed-editor.enable = lib.options.mkEnableOption "Zed Editor";

  config = lib.modules.mkIf config.euvlok.home.zed-editor.enable {
    programs.zed-editor.enable = true;
    programs.zed-editor.extraPackages = lib.attrsets.attrValues {
      inherit (pkgs.unstable)
        bash-language-server
        markdownlint-cli2
        neocmakelsp
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
      "ini"
      "beancount"
      "make"
      "neocmake"
      "meson"
      "stylelint"
      "http"
      "markdownlint"
    ];

    programs.zed-editor.userSettings = {
      auto_update = false; # Updates are managed by Nix.
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
        "*.slnx"
        "*.targets"
        "*.vbproj"
      ];
    };

    programs.zed-editor.userSettings.languages = {
      "Nix" = {
        language_servers = [
          "nil"
          "!nixd"
          "..."
        ];
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
        language_servers = [
          "json-language-server"
          "..."
        ];
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
        language_servers = [
          "bash-language-server"
          "..."
        ];
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
        language_servers = [
          "taplo"
          "..."
        ];
        formatter = "language_server";
      };
      "Markdown" = {
        language_servers = [
          "markdownlint"
          "..."
        ];
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
      nil.binary.path = lib.meta.getExe pkgs.unstable.nil;
      nil.settings.nil.nix.flake.autoArchive = true;

      cmake.binary = {
        path = lib.meta.getExe pkgs.unstable.neocmakelsp;
        arguments = [ "stdio" ];
      };

      bash-language-server.binary = {
        path = lib.meta.getExe pkgs.unstable.bash-language-server;
        arguments = [ "start" ];
      };

      yaml-language-server.binary = {
        path = lib.meta.getExe pkgs.unstable.yaml-language-server;
        arguments = [ "--stdio" ];
      };

      "json-language-server".binary = {
        path = lib.meta.getExe' pkgs.unstable.vscode-langservers-extracted "vscode-json-language-server";
        arguments = [ "--stdio" ];
      };

      taplo.binary = {
        path = lib.meta.getExe pkgs.unstable.taplo;
        arguments = [
          "lsp"
          "stdio"
        ];
      };

      typos.binary.path = lib.meta.getExe pkgs.unstable.typos-lsp;

      markdownlint.settings = {
        MD033 = false;
        MD041 = false;
        MD045 = false;
      };
    };
  };
}
