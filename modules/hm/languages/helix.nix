{ lib, config, ... }:
{
  config = lib.mkIf config.hm.helix.enable {
    programs.helix.languages.language-server =
      lib.optionalAttrs config.hm.languages.clojure.enable {
        clojure-lsp = {
          command = "clojure-lsp";
        };
      }
      // lib.optionalAttrs config.hm.languages.cpp.enable {
        clangd = {
          command = "clangd";
        };
      }
      // lib.optionalAttrs config.hm.languages.dart.enable {
        dart = {
          command = "dart";
          args = [
            "language-server"
            "--protocol=lsp"
          ];
        };
      }
      // lib.optionalAttrs config.hm.languages.elixir.enable {
        elixir-ls = {
          command = "elixir-ls";
        };
      }
      // lib.optionalAttrs config.hm.languages.fsharp.enable {
        fsautocomplete = {
          command = "fsautocomplete";
          args = [ "--background-service-enabled" ];
        };
      }
      // lib.optionalAttrs config.hm.languages.go.enable {
        gopls = {
          command = "gopls";
        };
      }
      // lib.optionalAttrs config.hm.languages.haskell.enable {
        haskell-language-server = {
          command = "haskell-language-server-wrapper";
          args = [ "--lsp" ];
        };
      }
      // lib.optionalAttrs config.hm.languages.javascript.enable {
        typescript-language-server = {
          command = "typescript-language-server";
          args = [ "--stdio" ];
        };
        deno = {
          command = "deno";
          args = [ "lsp" ];
          config = {
            enable = true;
            lint = true;
            unstable = true;
            format.options.lineWidth = 100;
            format.options.indentWidth = 2;
            javascript.format.options.indentWidth = 4;
            typescript.format.options.indentWidth = 4;
            suggest = {
              imports = {
                hosts = {
                  "https://deno.land" = true;
                  "https://cdn.nest.land" = true;
                  "https://crux.land" = true;
                };
              };
            };
            inlayHints = {
              enumMemberValues.enabled = true;
              functionLikeReturnTypes.enabled = true;
              parameterNames.enabled = "all";
              parameterTypes.enabled = true;
              propertyDeclarationTypes.enabled = true;
              variableTypes.enabled = true;
            };
          };
        };
      }
      // lib.optionalAttrs config.hm.languages.kotlin.enable {
        kotlin-language-server = {
          command = "kotlin-language-server";
        };
      }
      // lib.optionalAttrs config.hm.languages.lisp.enable {
        cl-lsp = {
          command = "cl-lsp";
        };
      }
      // lib.optionalAttrs config.hm.languages.lua.enable {
        lua-language-server = {
          command = "lua-language-server";
        };
      }
      // lib.optionalAttrs config.hm.languages.nim.enable {
        nimlangserver = {
          command = "nimlangserver";
        };
      }
      // lib.optionalAttrs config.hm.languages.ocaml.enable {
        ocamllsp = {
          command = "ocamllsp";
        };
      }
      // lib.optionalAttrs config.hm.languages.perl.enable {
        perlnavigator = {
          command = "perlnavigator";
          args = [ "--stdio" ];
        };
      }
      // lib.optionalAttrs config.hm.languages.php.enable {
        intelephense = {
          command = "intelephense";
          args = [ "--stdio" ];
        };
      }
      // lib.optionalAttrs config.hm.languages.python.enable {
        ruff = {
          command = "ruff";
          args = lib.splitString " " "server --preview";
          config.lineLength = 100;
          config.lint.extendSelect = [ "I" ];
        };
        pylsp = {
          command = "pylsp";
          plugins.pylsp_mypy.enable = true;
          plugins.pylsp_mypy.live_mode = true;
        };
        jedi = {
          command = "jedi-language-server";
        };
      }
      // lib.optionalAttrs config.hm.languages.ruby.enable {
        ruby-lsp = {
          command = "ruby-lsp";
        };
        solargraph = {
          command = "solargraph";
          args = [ "stdio" ];
        };
      }
      // lib.optionalAttrs config.hm.languages.rust.enable {
        rust-analyzer = {
          command = "rust-analyzer";
        };
      }
      // lib.optionalAttrs config.hm.languages.scala.enable {
        metals = {
          command = "metals";
        };
      }
      // lib.optionalAttrs config.hm.languages.swift.enable {
        sourcekit-lsp = {
          command = "sourcekit-lsp";
        };
      }
      // lib.optionalAttrs config.hm.languages.zig.enable {
        zls = {
          command = "zls";
        };
      };

    programs.helix.languages.language =
      lib.optionals config.hm.languages.python.enable [
        {
          name = "python";
          auto-format = true;
          language-servers = [
            "ruff"
            "pylsp"
            "jedi"
          ];
        }
      ]
      ++ lib.optionals config.hm.languages.javascript.enable [
        {
          name = "javascript";
          auto-format = true;
          indent.tab-width = 4;
          indent.unit = "    ";
          language-servers = [ "deno" ];
        }
        {
          name = "css";
          auto-format = true;
          language-servers = [ "deno" ];
        }
        {
          name = "json";
          auto-format = true;
          indent.tab-width = 2;
          indent.unit = "  ";
          language-servers = [ "deno" ];
        }
        {
          name = "typescript";
          auto-format = true;
          indent.tab-width = 4;
          indent.unit = "    ";
          language-servers = [ "deno" ];
        }
      ]
      ++ lib.optionals config.hm.languages.clojure.enable [
        {
          name = "clojure";
          auto-format = true;
          language-servers = [ "clojure-lsp" ];
        }
      ]
      ++ lib.optionals config.hm.languages.cpp.enable [
        {
          name = "c";
          auto-format = true;
          language-servers = [ "clangd" ];
        }
        {
          name = "cpp";
          auto-format = true;
          language-servers = [ "clangd" ];
        }
      ]
      ++ lib.optionals config.hm.languages.dart.enable [
        {
          name = "dart";
          auto-format = true;
          language-servers = [ "dart" ];
        }
      ]
      ++ lib.optionals config.hm.languages.elixir.enable [
        {
          name = "elixir";
          auto-format = true;
          language-servers = [ "elixir-ls" ];
        }
      ]
      ++ lib.optionals config.hm.languages.fsharp.enable [
        {
          name = "fsharp";
          auto-format = true;
          language-servers = [ "fsautocomplete" ];
        }
      ]
      ++ lib.optionals config.hm.languages.go.enable [
        {
          name = "go";
          auto-format = true;
          language-servers = [ "gopls" ];
        }
      ]
      ++ lib.optionals config.hm.languages.haskell.enable [
        {
          name = "haskell";
          auto-format = true;
          language-servers = [ "haskell-language-server" ];
        }
      ]
      ++ lib.optionals config.hm.languages.kotlin.enable [
        {
          name = "kotlin";
          auto-format = true;
          language-servers = [ "kotlin-language-server" ];
        }
      ]
      ++ lib.optionals config.hm.languages.lisp.enable [
        {
          name = "common-lisp";
          auto-format = true;
          language-servers = [ "cl-lsp" ];
        }
      ]
      ++ lib.optionals config.hm.languages.lua.enable [
        {
          name = "lua";
          auto-format = true;
          language-servers = [ "lua-language-server" ];
        }
      ]
      ++ lib.optionals config.hm.languages.nim.enable [
        {
          name = "nim";
          auto-format = true;
          language-servers = [ "nimlangserver" ];
        }
      ]
      ++ lib.optionals config.hm.languages.ocaml.enable [
        {
          name = "ocaml";
          auto-format = true;
          language-servers = [ "ocamllsp" ];
        }
      ]
      ++ lib.optionals config.hm.languages.perl.enable [
        {
          name = "perl";
          auto-format = true;
          language-servers = [ "perlnavigator" ];
        }
      ]
      ++ lib.optionals config.hm.languages.php.enable [
        {
          name = "php";
          auto-format = true;
          language-servers = [ "intelephense" ];
        }
      ]
      ++ lib.optionals config.hm.languages.ruby.enable [
        {
          name = "ruby";
          auto-format = true;
          language-servers = [
            "ruby-lsp"
            "solargraph"
          ];
        }
      ]
      ++ lib.optionals config.hm.languages.rust.enable [
        {
          name = "rust";
          auto-format = true;
          language-servers = [ "rust-analyzer" ];
        }
      ]
      ++ lib.optionals config.hm.languages.scala.enable [
        {
          name = "scala";
          auto-format = true;
          language-servers = [ "metals" ];
        }
      ]
      ++ lib.optionals config.hm.languages.swift.enable [
        {
          name = "swift";
          auto-format = true;
          language-servers = [ "sourcekit-lsp" ];
        }
      ]
      ++ lib.optionals config.hm.languages.zig.enable [
        {
          name = "zig";
          auto-format = true;
          language-servers = [ "zls" ];
        }
      ];
  };
}
