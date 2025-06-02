{ lib, config, ... }:
{
  options.hm.zed-editor.enable = lib.mkEnableOption "Zed Editor";

  config = lib.mkIf config.hm.zed-editor.enable {
    programs.zed-editor.enable = true;
    programs.zed-editor.extensions =
      [
        "nix"
        "json5"
        "xml"
        "typos"
        "cspell"
        "biome"
        "unicode"
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
      ]
      ++ lib.optionals config.programs.fish.enable [ "fish" ]
      ++ lib.optionals config.programs.nushell.enable [ "nu" ]
      ++ (lib.optionals config.hm.languages.csharp [ "csharp" ])
      ++ (lib.optionals config.hm.languages.clojure [ "clojure" ])
      ++ (lib.optionals config.hm.languages.dart [
        "dart"
        "flutter-snippets"
      ])
      ++ (lib.optionals config.hm.languages.elixir [ "elixir" ])
      ++ (lib.optionals config.hm.languages.fsharp [ "fsharp" ])
      ++ (lib.optionals config.hm.languages.go [
        "go-snippets"
        "golangci-lint"
        "gosum"
        "templ"
      ])
      ++ (lib.optionals config.hm.languages.haskell [ "haskell" ])
      ++ (lib.optionals config.hm.languages.java [
        "java"
        "java-eclipse-jdtls"
      ])
      ++ (lib.optionals config.hm.languages.javascript [
        "astro"
        "css-modules-kit"
        "ejs"
        "ember"
        "html-jinja"
        "jinja2"
        "less"
        "nestjs-snippets"
        "pug"
        "react-typescript-snippets"
        "scss"
        "svelte"
        "svelte-snippets"
        "tailwind-theme"
        "vue"
        "vue-snippets"
      ])
      ++ (lib.optionals config.hm.languages.kotlin [ "kotlin" ])
      ++ (lib.optionals config.hm.languages.lisp [
        "scheme"
        "elisp"
      ])
      ++ (lib.optionals config.hm.languages.lua [
        "lua"
        "luau"
      ])
      ++ (lib.optionals config.hm.languages.nim [ "nim" ])
      ++ (lib.optionals config.hm.languages.ocaml [ "ocaml" ])
      ++ (lib.optionals config.hm.languages.perl [ "perl" ])
      ++ (lib.optionals config.hm.languages.php [
        "php"
        "blade"
        "twig"
      ])
      ++ (lib.optionals config.hm.languages.python [
        "python-snippets"
        "python-requirements"
        "python-refactoring"
        "basedpyright"
        "django-snippets"
        "flask-snippets"
      ])
      ++ (lib.optionals config.hm.languages.ruby [
        "ruby"
        "thrift"
        "haml"
      ])
      ++ (lib.optionals config.hm.languages.rust [
        "cargo-appraiser"
        "crates-lsp"
      ])
      ++ (lib.optionals config.hm.languages.scala [ "scala" ])
      ++ (lib.optionals config.hm.languages.swift [
        "swift"
        "package-swift-lsp"
      ])
      ++ (lib.optionals config.hm.languages.zig [
        "zig"
        "ziggy"
      ]);

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
    };

    programs.zed-editor.userSettings.languages =
      {
        "Nix" = {
          language_servers = [ "nil" ];
          formatter = {
            external = {
              command = "nixfmt-classic";
            };
          };
        };
        "YAML" = {
          formatter = "language_server";
        };
        "JSON" = {
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
      }
      # C/C++
      // (lib.optionalAttrs config.hm.languages.cpp {
        "C" = {
          language_servers = [ "clangd" ];
          formatter = {
            external = {
              command = "clang-format";
            };
          };
        };
        "C++" = {
          language_servers = [ "clangd" ];
          formatter = {
            external = {
              command = "clang-format";
            };
          };
        };
      })
      # Csharp
      // (lib.optionalAttrs config.hm.languages.csharp {
        "CSharp" = {
          language_servers = [ "omnisharp" ];
        };
      })
      # Clojure
      // (lib.optionalAttrs config.hm.languages.clojure {
        "Clojure" = {
        };
      })
      # Dart
      // (lib.optionalAttrs config.hm.languages.dart {
        "Dart" = {
          language_servers = [ "dart" ];
          formatter = "language_server";
        };
      })
      # Elixir
      // (lib.optionalAttrs config.hm.languages.elixir {
        "Elixir" = {
          language_servers = [ "elixir-ls" ];
          formatter = "language_server";
        };
      })
      # F#
      // (lib.optionalAttrs config.hm.languages.fsharp {
        "F#" = {
          language_servers = [ "fsautocomplete" ];
        };
      })
      # Go
      // (lib.optionalAttrs config.hm.languages.go {
        "Go" = {
          language_servers = [ "gopls" ];
          formatter = "language_server";
        };
      })
      # Haskell
      // (lib.optionalAttrs config.hm.languages.haskell {
        "Haskell" = {
          language_servers = [ "haskell-language-server" ];
          formatter = "language_server";
        };
      })
      # Java
      // (lib.optionalAttrs config.hm.languages.java {
        "Java" = {
          language_servers = [ "jdtls" ];
          formatter = "language_server";
          prettier.allowed = false; # Use JDTLS
        };
      })
      # JavaScript/TypeScript
      // (lib.optionalAttrs config.hm.languages.javascript {
        "JavaScript" = {
          language_servers = [
            "typescript-language-server"
            "eslint_d"
          ];
          formatter = {
            external = {
              command = "prettier";
              arguments = [
                "--parser"
                "javascript"
                "--stdin-filepath"
                "{buffer_path}"
              ];
            };
          };
        };
        "TypeScript" = {
          language_servers = [
            "typescript-language-server"
            "eslint_d"
          ];
          formatter = {
            external = {
              command = "prettier";
              arguments = [
                "--parser"
                "typescript"
                "--stdin-filepath"
                "{buffer_path}"
              ];
            };
          };
        };
        "TSX" = {
          language_servers = [
            "typescript-language-server"
            "eslint_d"
          ];
          formatter = {
            external = {
              command = "prettier";
              arguments = [
                "--parser"
                "tsx"
                "--stdin-filepath"
                "{buffer_path}"
              ];
            };
          };
        };
        "JSX" = {
          language_servers = [
            "typescript-language-server"
            "eslint_d"
          ];
          formatter = {
            external = {
              command = "prettier";
              arguments = [
                "--parser"
                "jsx"
                "--stdin-filepath"
                "{buffer_path}"
              ];
            };
          };
        };
      })
      # Kotlin
      // (lib.optionalAttrs config.hm.languages.kotlin {
        "Kotlin" = {
          language_servers = [ "kotlin-language-server" ];
          formatter = "language_server";
        };
      })
      # Lua
      // (lib.optionalAttrs config.hm.languages.lua {
        "Lua" = {
          language_servers = [ "lua-language-server" ];
          formatter = {
            external = {
              command = "stylua";
              arguments = [
                "--stdin-filepath"
                "{buffer_path}"
                "-"
              ];
            };
          };
        };
      })
      # Nim
      // (lib.optionalAttrs config.hm.languages.nim {
        "Nim" = {
          language_servers = [ "nimlsp" ];
        };
      })
      # OCaml
      // (lib.optionalAttrs config.hm.languages.ocaml {
        "OCaml" = {
          language_servers = [ "ocamllsp" ];
          formatter = {
            external = {
              command = "ocamlformat";
              arguments = [
                "--name"
                "{buffer_path}"
                "-"
              ];
            };
          };
        };
      })
      # Perl
      // (lib.optionalAttrs config.hm.languages.perl {
        "Perl" = {
          language_servers = [ "perlnavigator" ];
        };
      })
      # PHP
      // (lib.optionalAttrs config.hm.languages.php {
        "PHP" = {
          language_servers = [ "intelephense" ];
          formatter = "language_server";
          prettier.allowed = false;
        };
      })
      # Python
      // (lib.optionalAttrs config.hm.languages.python {
        "Python" = {
          language_servers = [
            "ruff"
            "pyright"
          ];
          formatter = {
            external = {
              command = "ruff";
              arguments = [
                "format"
                "--stdin-filename"
                "{buffer_path}"
                "-"
              ];
            };
          };
        };
      })
      # Ruby
      // (lib.optionalAttrs config.hm.languages.ruby {
        "Ruby" = {
          language_servers = [ "ruby-lsp" ];
          formatter = "language_server";
        };
      })
      # Rust
      // (lib.optionalAttrs config.hm.languages.rust {
        "Rust" = {
          language_servers = [ "rust-analyzer" ];
          formatter = "language_server";
        };
      })
      # Scala
      // (lib.optionalAttrs config.hm.languages.scala {
        "Scala" = {
          language_servers = [ "metals" ];
          formatter = "language_server";
        };
      })
      # Swift
      // (lib.optionalAttrs config.hm.languages.swift {
        "Swift" = {
          language_servers = [ "sourcekit-lsp" ];
          formatter = "language_server";
        };
      })
      # Zig
      // (lib.optionalAttrs config.hm.languages.zig {
        "Zig" = {
          language_servers = [ "zls" ];
          formatter = "language_server";
        };
      });

    programs.zed-editor.userSettings.lsp =
      # C/C++
      (lib.optionalAttrs config.hm.languages.cpp {
        clangd = {
          binary = {
            path = "clangd";
            arguments = [
              "--header-insertion=iwyu"
              "--completion-style=detailed"
              "--fallback-style=llvm"
            ];
          };
        };
      })
      # CSharp
      // (lib.optionalAttrs config.hm.languages.csharp {
        omnisharp = {
          binary = {
            path = "omnisharp";
            arguments = [ "-lsp" ];
          };
        };
      })
      # Dart
      // (lib.optionalAttrs config.hm.languages.dart {
        dart = {
          binary = {
            path = "dart";
            arguments = [
              "language-server"
              "--protocol=lsp"
            ];
          };
        };
      })
      # Elixir
      // (lib.optionalAttrs config.hm.languages.elixir {
        "elixir-ls" = {
          binary = {
            path = "elixir-ls";
          };
        };
      })
      # F#
      // (lib.optionalAttrs config.hm.languages.fsharp {
        fsautocomplete = {
          binary = {
            path = "fsautocomplete";
            arguments = [ "--background-service-enabled" ];
          };
        };
      })
      # Go
      // (lib.optionalAttrs config.hm.languages.go {
        gopls = {
          binary = {
            path = "gopls";
          };
          initialization_options = {
            gofumpt = true;
            staticcheck = true;
            vulncheck = "Imports";
            hints = {
              assignVariableTypes = true;
              compositeLiteralFields = true;
              compositeLiteralTypes = true;
              constantValues = true;
              functionTypeParameters = true;
              parameterNames = true;
              rangeVariableTypes = true;
            };
          };
        };
      })
      # Haskell
      // (lib.optionalAttrs config.hm.languages.haskell {
        "haskell-language-server" = {
          binary = {
            path = "haskell-language-server-wrapper"; # Or haskell-language-server
            arguments = [ "--lsp" ];
          };
        };
      })
      # Java
      // (lib.optionalAttrs config.hm.languages.java {
        jdtls = {
          binary = {
            path = "jdtls";
          };
        };
      })
      # JavaScript/TypeScript
      // (lib.optionalAttrs config.hm.languages.javascript {
        "typescript-language-server" = {
          # Or vtsls if preferred
          binary = {
            path = "typescript-language-server";
            arguments = [ "--stdio" ];
          };
        };
        eslint_d = {
          binary = {
            path = "eslint_d";
          };
        };
      })
      # Kotlin
      // (lib.optionalAttrs config.hm.languages.kotlin {
        "kotlin-language-server" = {
          binary = {
            path = "kotlin-language-server";
          };
        };
      })
      # Lua
      // (lib.optionalAttrs config.hm.languages.lua {
        "lua-language-server" = {
          binary = {
            path = "lua-language-server";
          };
          initialization_options.Lua = {
            telemetry.enable = false;
            workspace.checkThirdParty = false;
          };
        };
      })
      # Nim
      // (lib.optionalAttrs config.hm.languages.nim {
        nimlsp = {
          binary = {
            path = "nimlsp";
          };
        };
      })
      # OCaml
      // (lib.optionalAttrs config.hm.languages.ocaml {
        ocamllsp = {
          binary = {
            path = "ocamllsp";
          };
        };
      })
      # Perl
      // (lib.optionalAttrs config.hm.languages.perl {
        perlnavigator = {
          binary = {
            path = "perlnavigator";
          };
        };
      })
      # PHP
      // (lib.optionalAttrs config.hm.languages.php {
        intelephense = {
          binary = {
            path = "intelephense";
            arguments = [ "--stdio" ];
          };
        };
      })
      # Python
      // (lib.optionalAttrs config.hm.languages.python {
        pyright = {
          initialization_options = {
            python = {
              analysis = {
                typeCheckingMode = "strict";
              };
            };
          };
        };
        ruff = {
          binary = {
            path = "ruff";
            arguments = [
              "server"
              "--preview"
            ];
          };
        };
      })
      # Rust
      // (lib.optionalAttrs config.hm.languages.rust {
        "rust-analyzer" = {
          binary = {
            path = "rust-analyzer";
          };
          initialization_options = {
            cargo = {
              buildScripts.enable = true;
              features = "all";
            };
            procMacro.enable = true;
            diagnostics.disabled = [ "unresolved-proc-macro" ];
            # checkOnSave.command = "clippy"; # Example
          };
        };
      })
      # Scala
      // (lib.optionalAttrs config.hm.languages.scala {
        metals = {
          binary = {
            path = "metals";
          };
        };
      })
      # Swift
      // (lib.optionalAttrs config.hm.languages.swift {
        "sourcekit-lsp" = {
          binary = {
            path = "sourcekit-lsp";
          };
        };
      })
      # Zig
      // (lib.optionalAttrs config.hm.languages.zig {
        zls = {
          binary = {
            path = "zls";
          };
        };
      });
  };
}
