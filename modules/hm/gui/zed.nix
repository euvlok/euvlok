{ lib, config, ... }:
{
  options.hm.zed-editor.enable = lib.mkEnableOption "Zed Editor";

  config = lib.mkIf config.hm.zed-editor.enable {
    programs.zed-editor.enable = true;
    programs.zed-editor.extensions = [
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
    ++ (lib.optionals config.hm.languages.csharp.enable [ "csharp" ])
    ++ (lib.optionals config.hm.languages.clojure.enable [ "clojure" ])
    ++ (lib.optionals config.hm.languages.dart.enable [
      "dart"
      "flutter-snippets"
    ])
    ++ (lib.optionals config.hm.languages.elixir.enable [ "elixir" ])
    ++ (lib.optionals config.hm.languages.fsharp.enable [ "fsharp" ])
    ++ (lib.optionals config.hm.languages.go.enable [
      "go-snippets"
      "golangci-lint"
      "gosum"
      "templ"
    ])
    ++ (lib.optionals config.hm.languages.haskell.enable [ "haskell" ])
    ++ (lib.optionals config.hm.languages.java.enable [
      "java"
      "java-eclipse-jdtls"
    ])
    ++ (lib.optionals config.hm.languages.javascript.enable [
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
    ++ (lib.optionals config.hm.languages.kotlin.enable [ "kotlin" ])
    ++ (lib.optionals config.hm.languages.lisp.enable [
      "scheme"
      "elisp"
    ])
    ++ (lib.optionals config.hm.languages.lua.enable [
      "lua"
      "luau"
    ])
    ++ (lib.optionals config.hm.languages.nim.enable [ "nim" ])
    ++ (lib.optionals config.hm.languages.ocaml.enable [ "ocaml" ])
    ++ (lib.optionals config.hm.languages.perl.enable [ "perl" ])
    ++ (lib.optionals config.hm.languages.php.enable [
      "php"
      "blade"
      "twig"
    ])
    ++ (lib.optionals config.hm.languages.python.enable [
      "python-snippets"
      "python-requirements"
      "python-refactoring"
      "basedpyright"
      "django-snippets"
      "flask-snippets"
    ])
    ++ (lib.optionals config.hm.languages.ruby.enable [
      "ruby"
      "thrift"
      "haml"
    ])
    ++ (lib.optionals config.hm.languages.rust.enable [
      "cargo-appraiser"
      "crates-lsp"
    ])
    ++ (lib.optionals config.hm.languages.scala.enable [ "scala" ])
    ++ (lib.optionals config.hm.languages.swift.enable [
      "swift"
      "package-swift-lsp"
    ])
    ++ (lib.optionals config.hm.languages.zig.enable [
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

    programs.zed-editor.userSettings.languages = {
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
    // (lib.optionalAttrs config.hm.languages.cpp.enable {
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
    // (lib.optionalAttrs config.hm.languages.csharp.enable {
      "CSharp" = {
        language_servers = [ "omnisharp" ];
      };
    })
    # Clojure
    // (lib.optionalAttrs config.hm.languages.clojure.enable {
      "Clojure" = {
      };
    })
    # Dart
    // (lib.optionalAttrs config.hm.languages.dart.enable {
      "Dart" = {
        language_servers = [ "dart" ];
        formatter = "language_server";
      };
    })
    # Elixir
    // (lib.optionalAttrs config.hm.languages.elixir.enable {
      "Elixir" = {
        language_servers = [ "elixir-ls" ];
        formatter = "language_server";
      };
    })
    # F#
    // (lib.optionalAttrs config.hm.languages.fsharp.enable {
      "F#" = {
        language_servers = [ "fsautocomplete" ];
      };
    })
    # Go
    // (lib.optionalAttrs config.hm.languages.go.enable {
      "Go" = {
        language_servers = [ "gopls" ];
        formatter = "language_server";
      };
    })
    # Haskell
    // (lib.optionalAttrs config.hm.languages.haskell.enable {
      "Haskell" = {
        language_servers = [ "haskell-language-server" ];
        formatter = "language_server";
      };
    })
    # Java
    // (lib.optionalAttrs config.hm.languages.java.enable {
      "Java" = {
        language_servers = [ "jdtls" ];
        formatter = "language_server";
        prettier.allowed = false; # Use JDTLS
      };
    })
    # JavaScript/TypeScript
    // (lib.optionalAttrs config.hm.languages.javascript.enable {
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
    // (lib.optionalAttrs config.hm.languages.kotlin.enable {
      "Kotlin" = {
        language_servers = [ "kotlin-language-server" ];
        formatter = "language_server";
      };
    })
    # Lua
    // (lib.optionalAttrs config.hm.languages.lua.enable {
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
    // (lib.optionalAttrs config.hm.languages.nim.enable {
      "Nim" = {
        language_servers = [ "nimlsp" ];
      };
    })
    # OCaml
    // (lib.optionalAttrs config.hm.languages.ocaml.enable {
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
    // (lib.optionalAttrs config.hm.languages.perl.enable {
      "Perl" = {
        language_servers = [ "perlnavigator" ];
      };
    })
    # PHP
    // (lib.optionalAttrs config.hm.languages.php.enable {
      "PHP" = {
        language_servers = [ "intelephense" ];
        formatter = "language_server";
        prettier.allowed = false;
      };
    })
    # Python
    // (lib.optionalAttrs config.hm.languages.python.enable {
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
    // (lib.optionalAttrs config.hm.languages.ruby.enable {
      "Ruby" = {
        language_servers = [ "ruby-lsp" ];
        formatter = "language_server";
      };
    })
    # Rust
    // (lib.optionalAttrs config.hm.languages.rust.enable {
      "Rust" = {
        language_servers = [ "rust-analyzer" ];
        formatter = "language_server";
      };
    })
    # Scala
    // (lib.optionalAttrs config.hm.languages.scala.enable {
      "Scala" = {
        language_servers = [ "metals" ];
        formatter = "language_server";
      };
    })
    # Swift
    // (lib.optionalAttrs config.hm.languages.swift.enable {
      "Swift" = {
        language_servers = [ "sourcekit-lsp" ];
        formatter = "language_server";
      };
    })
    # Zig
    // (lib.optionalAttrs config.hm.languages.zig.enable {
      "Zig" = {
        language_servers = [ "zls" ];
        formatter = "language_server";
      };
    });

    programs.zed-editor.userSettings.lsp =
      # C/C++
      (lib.optionalAttrs config.hm.languages.cpp.enable {
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
      // (lib.optionalAttrs config.hm.languages.csharp.enable {
        omnisharp = {
          binary = {
            path = "omnisharp";
            arguments = [ "-lsp" ];
          };
        };
      })
      # Dart
      // (lib.optionalAttrs config.hm.languages.dart.enable {
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
      // (lib.optionalAttrs config.hm.languages.elixir.enable {
        "elixir-ls" = {
          binary = {
            path = "elixir-ls";
          };
        };
      })
      # F#
      // (lib.optionalAttrs config.hm.languages.fsharp.enable {
        fsautocomplete = {
          binary = {
            path = "fsautocomplete";
            arguments = [ "--background-service-enabled" ];
          };
        };
      })
      # Go
      // (lib.optionalAttrs config.hm.languages.go.enable {
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
      // (lib.optionalAttrs config.hm.languages.haskell.enable {
        "haskell-language-server" = {
          binary = {
            path = "haskell-language-server-wrapper"; # Or haskell-language-server
            arguments = [ "--lsp" ];
          };
        };
      })
      # Java
      // (lib.optionalAttrs config.hm.languages.java.enable {
        jdtls = {
          binary = {
            path = "jdtls";
          };
        };
      })
      # JavaScript/TypeScript
      // (lib.optionalAttrs config.hm.languages.javascript.enable {
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
      // (lib.optionalAttrs config.hm.languages.kotlin.enable {
        "kotlin-language-server" = {
          binary = {
            path = "kotlin-language-server";
          };
        };
      })
      # Lua
      // (lib.optionalAttrs config.hm.languages.lua.enable {
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
      // (lib.optionalAttrs config.hm.languages.nim.enable {
        nimlsp = {
          binary = {
            path = "nimlsp";
          };
        };
      })
      # OCaml
      // (lib.optionalAttrs config.hm.languages.ocaml.enable {
        ocamllsp = {
          binary = {
            path = "ocamllsp";
          };
        };
      })
      # Perl
      // (lib.optionalAttrs config.hm.languages.perl.enable {
        perlnavigator = {
          binary = {
            path = "perlnavigator";
          };
        };
      })
      # PHP
      // (lib.optionalAttrs config.hm.languages.php.enable {
        intelephense = {
          binary = {
            path = "intelephense";
            arguments = [ "--stdio" ];
          };
        };
      })
      # Python
      // (lib.optionalAttrs config.hm.languages.python.enable {
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
      // (lib.optionalAttrs config.hm.languages.rust.enable {
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
      // (lib.optionalAttrs config.hm.languages.scala.enable {
        metals = {
          binary = {
            path = "metals";
          };
        };
      })
      # Swift
      // (lib.optionalAttrs config.hm.languages.swift.enable {
        "sourcekit-lsp" = {
          binary = {
            path = "sourcekit-lsp";
          };
        };
      })
      # Zig
      // (lib.optionalAttrs config.hm.languages.zig.enable {
        zls = {
          binary = {
            path = "zls";
          };
        };
      });
  };
}
