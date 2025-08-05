{ lib, config, ... }:
let
  language-server = {
    bash-language-server = {
      args = [ "start" ];
      command = "bash-language-server";
      config.enable = true;
    };
    nil = {
      command = "nil";
      config.nil.formatting.command = [ "nixfmt" ];
    };
    yaml-language-server = {
      command = "yaml-language-server";
      args = [ "--stdio" ];
      config = {
        yaml = {
          format.enable = true;
          validation = true;
          schemas.https = true;
        };
      };
    };
    taplo = {
      command = "taplo";
      args = lib.splitString " " "lsp stdio";
      config.formatter.alignEntries = true;
      config.formatter.columnWidth = 100;
    };
  }
  // lib.optionalAttrs config.hm.languages.clojure {
    clojure-lsp = {
      command = "clojure-lsp";
    };
  }
  // lib.optionalAttrs config.hm.languages.cpp {
    clangd = {
      command = "clangd";
    };
  }
  // lib.optionalAttrs config.hm.languages.dart {
    dart = {
      command = "dart";
      args = [
        "language-server"
        "--protocol=lsp"
      ];
    };
  }
  // lib.optionalAttrs config.hm.languages.elixir {
    elixir-ls = {
      command = "elixir-ls";
    };
  }
  // lib.optionalAttrs config.hm.languages.fsharp {
    fsautocomplete = {
      command = "fsautocomplete";
      args = [ "--background-service-enabled" ];
    };
  }
  // lib.optionalAttrs config.hm.languages.go {
    gopls = {
      command = "gopls";
    };
  }
  // lib.optionalAttrs config.hm.languages.haskell {
    haskell-language-server = {
      command = "haskell-language-server-wrapper";
      args = [ "--lsp" ];
    };
  }
  // lib.optionalAttrs config.hm.languages.javascript {
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
  // lib.optionalAttrs config.hm.languages.kotlin {
    kotlin-language-server = {
      command = "kotlin-language-server";
    };
  }
  // lib.optionalAttrs config.hm.languages.lisp {
    cl-lsp = {
      command = "cl-lsp";
    };
  }
  // lib.optionalAttrs config.hm.languages.lua {
    lua-language-server = {
      command = "lua-language-server";
    };
  }
  // lib.optionalAttrs config.hm.languages.nim {
    nimlangserver = {
      command = "nimlangserver";
    };
  }
  // lib.optionalAttrs config.hm.languages.ocaml {
    ocamllsp = {
      command = "ocamllsp";
    };
  }
  // lib.optionalAttrs config.hm.languages.perl {
    perlnavigator = {
      command = "perlnavigator";
      args = [ "--stdio" ];
    };
  }
  // lib.optionalAttrs config.hm.languages.php {
    intelephense = {
      command = "intelephense";
      args = [ "--stdio" ];
    };
  }
  // lib.optionalAttrs config.hm.languages.python {
    ruff = {
      command = "ruff";
      args = lib.splitString " " "server --preview";
      config.lineLength = 100;
      config.lint.extendSelect = [ "I" ];
    };
  }
  // lib.optionalAttrs config.hm.languages.ruby {
    ruby-lsp = {
      command = "ruby-lsp";
    };
    solargraph = {
      command = "solargraph";
      args = [ "stdio" ];
    };
  }
  // lib.optionalAttrs config.hm.languages.rust {
    rust-analyzer = {
      command = "rust-analyzer";
    };
  }
  // lib.optionalAttrs config.hm.languages.scala {
    metals = {
      command = "metals";
    };
  }
  // lib.optionalAttrs config.hm.languages.swift {
    sourcekit-lsp = {
      command = "sourcekit-lsp";
    };
  }
  // lib.optionalAttrs config.hm.languages.zig {
    zls = {
      command = "zls";
    };
  };

  language = [
    {
      name = "nix";
      auto-format = true;
      language-servers = [ "nil" ];
    }
    {
      name = "bash";
      auto-format = true;
      diagnostic-severity = "warning";
      formatter.args = [ "-w" ];
      formatter.command = "shfmt";
      language-servers = [ "bash-language-server" ];
    }
    {
      name = "yaml";
      auto-format = true;
      language-servers = [ "yaml-language-server" ];
    }
    {
      name = "toml";
      auto-format = true;
      language-servers = [ "taplo" ];
    }
  ]
  ++ lib.optionals config.hm.languages.python [
    {
      name = "python";
      auto-format = true;
      language-servers = [ "ruff" ];
    }
  ]
  ++ lib.optionals config.hm.languages.javascript [
    {
      name = "javascript";
      auto-format = true;
      indent.tab-width = 4;
      indent.unit = "    ";
      language-servers = config.hm.languages.javascript [ "deno" ];
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
  ++ lib.optionals config.hm.languages.clojure [
    {
      name = "clojure";
      auto-format = true;
      language-servers = [ "clojure-lsp" ];
    }
  ]
  ++ lib.optionals config.hm.languages.cpp [
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
  ++ lib.optionals config.hm.languages.dart [
    {
      name = "dart";
      auto-format = true;
      language-servers = [ "dart" ];
    }
  ]
  ++ lib.optionals config.hm.languages.elixir [
    {
      name = "elixir";
      auto-format = true;
      language-servers = [ "elixir-ls" ];
    }
  ]
  ++ lib.optionals config.hm.languages.fsharp [
    {
      name = "fsharp";
      auto-format = true;
      language-servers = [ "fsautocomplete" ];
    }
  ]
  ++ lib.optionals config.hm.languages.go [
    {
      name = "go";
      auto-format = true;
      language-servers = [ "gopls" ];
    }
  ]
  ++ lib.optionals config.hm.languages.haskell [
    {
      name = "haskell";
      auto-format = true;
      language-servers = [ "haskell-language-server" ];
    }
  ]
  ++ lib.optionals config.hm.languages.kotlin [
    {
      name = "kotlin";
      auto-format = true;
      language-servers = [ "kotlin-language-server" ];
    }
  ]
  ++ lib.optionals config.hm.languages.lisp [
    {
      name = "common-lisp";
      auto-format = true;
      language-servers = [ "cl-lsp" ];
    }
  ]
  ++ lib.optionals config.hm.languages.lua [
    {
      name = "lua";
      auto-format = true;
      language-servers = [ "lua-language-server" ];
    }
  ]
  ++ lib.optionals config.hm.languages.nim [
    {
      name = "nim";
      auto-format = true;
      language-servers = [ "nimlangserver" ];
    }
  ]
  ++ lib.optionals config.hm.languages.ocaml [
    {
      name = "ocaml";
      auto-format = true;
      language-servers = [ "ocamllsp" ];
    }
  ]
  ++ lib.optionals config.hm.languages.perl [
    {
      name = "perl";
      auto-format = true;
      language-servers = [ "perlnavigator" ];
    }
  ]
  ++ lib.optionals config.hm.languages.php [
    {
      name = "php";
      auto-format = true;
      language-servers = [ "intelephense" ];
    }
  ]
  ++ lib.optionals config.hm.languages.ruby [
    {
      name = "ruby";
      auto-format = true;
      language-servers = [
        "ruby-lsp"
        "solargraph"
      ];
    }
  ]
  ++ lib.optionals config.hm.languages.rust [
    {
      name = "rust";
      auto-format = true;
      language-servers = [ "rust-analyzer" ];
    }
  ]
  ++ lib.optionals config.hm.languages.scala [
    {
      name = "scala";
      auto-format = true;
      language-servers = [ "metals" ];
    }
  ]
  ++ lib.optionals config.hm.languages.swift [
    {
      name = "swift";
      auto-format = true;
      language-servers = [ "sourcekit-lsp" ];
    }
  ]
  ++ lib.optionals config.hm.languages.zig [
    {
      name = "zig";
      auto-format = true;
      language-servers = [ "zls" ];
    }
  ];
in
{
  programs.helix.languages = { inherit language-server language; };
}
