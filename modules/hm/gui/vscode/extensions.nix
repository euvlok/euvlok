{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  mkExt = (pkgs.callPackage ./lib.nix { inherit inputs osConfig; }).mkExt;

  extensions =
    [
      # Nix
      (mkExt "bbenoist" "nix")
      (mkExt "jnoortheen" "nix-ide")
      (mkExt "kamadorueda" "alejandra")

      # Shells
      (mkExt "bmalehorn" "shell-syntax")
      (mkExt "mads-hartmann" "bash-ide-vscode")
      (mkExt "rogalmic" "bash-debug")
      (mkExt "timonwong" "shellcheck")

      # Code Quality
      (mkExt "streetsidesoftware" "code-spell-checker")
      (mkExt "usernamehw" "errorlens")

      # Markup languages
      (mkExt "davidanson" "vscode-markdownlint")
      (mkExt "redhat" "vscode-xml")
      (mkExt "redhat" "vscode-yaml")
      (mkExt "tamasfe" "even-better-toml")
      (mkExt "yzhang" "markdown-all-in-one")
      (mkExt "zainchen" "json")

      # Programming Languages
      (mkExt "dbaeumer" "vscode-eslint")
      (mkExt "mgmcdermott" "vscode-language-babel")

      # Misc
      (mkExt "editorconfig" "editorconfig")
      (mkExt "oderwat" "indent-rainbow")
      (mkExt "visualstudioexptteam" "vscodeintellicode")
    ]
    ++ lib.optionals config.programs.direnv.enable [ (mkExt "mkhl" "direnv") ]
    ++ lib.optionals config.programs.fish.enable [ (mkExt "bmalehorn" "vscode-fish") ]
    ++ lib.optionals config.programs.nushell.enable [
      (mkExt "thenuprojectcontributors" "vscode-nushell-lang")
    ]

    # Language-specific extensions
    ++ lib.optionals config.hm.languages.csharp [
      (mkExt "ms-dotnettools" "csharp")
      (mkExt "ms-dotnettools" "vscode-dotnet-runtime")
    ]
    ++ lib.optionals config.hm.languages.cpp [
      (mkExt "ms-vscode" "cmake-tools")
      (mkExt "ms-vscode" "cpptools")
      (mkExt "ms-vscode" "cpptools-extension-pack")
      (mkExt "twxs" "cmake")
    ]
    ++ lib.optionals config.hm.languages.rust [
      (mkExt "fill-labs" "dependi")
      (mkExt "rust-lang" "rust-analyzer")
      (mkExt "vadimcn" "vscode-lldb")
    ]
    ++ lib.optionals config.hm.languages.lua [
      (mkExt "keyring" "lua")
      (mkExt "sumneko" "lua")
    ]
    ++ lib.optionals config.hm.languages.javascript [
      (mkExt "bradlc" "vscode-tailwindcss")
      (mkExt "christian-kohler" "npm-intellisense")
      (mkExt "denoland" "vscode-deno")
      (mkExt "esbenp" "prettier-vscode")
      (mkExt "esbenp" "prettier-vscode")
      (mkExt "ms-vscode" "vscode-typescript-next")
      (mkExt "syler" "sass-indented")
    ]
    ++ lib.optionals config.hm.languages.nim [
      (mkExt "nimLang" "nimlang")
      (mkExt "nimsaem" "nimvscode")
    ]
    ++ lib.optionals config.hm.languages.go [
      (mkExt "golang" "go")
      (mkExt "premparihar" "gotestexplorer")
    ]
    ++ lib.optionals config.hm.languages.swift [
      (mkExt "swift-server" "swift")
      (mkExt "vknabel" "swift-coverage")
    ]
    ++ lib.optionals config.hm.languages.ruby [
      (mkExt "rebornix" "ruby")
      (mkExt "shopify" "ruby-lsp")
      (mkExt "sorbet" "sorbet-vscode-extension")
      (mkExt "wingrunr21" "vscode-ruby")
    ]
    ++ lib.optionals config.hm.languages.python [
      (mkExt "charliermarsh" "ruff")
      (mkExt "ms-python" "debugpy")
      (mkExt "ms-python" "python")
      (mkExt "ms-python" "vscode-pylance")
      (mkExt "ms-toolsai" "jupyter")
    ]
    ++ lib.optionals config.hm.languages.php [
      (mkExt "devsense" "phptools-vscode")
      (mkExt "bmewburn" "vscode-intelephense-client")
      (mkExt "xdebug" "php-debug")
    ]
    ++ lib.optionals config.hm.languages.kotlin [ (mkExt "fwcd" "kotlin") ]
    ++ lib.optionals config.hm.languages.elixir [ (mkExt "jakebecker" "elixir-ls") ]
    ++ lib.optionals config.hm.languages.java [
      (mkExt "oracle" "oracle-java")
      (mkExt "redhat" "java")
      (mkExt "vscjava" "vscode-gradle")
      (mkExt "vscjava" "vscode-java-debug")
      (mkExt "vscjava" "vscode-java-dependency")
      (mkExt "vscjava" "vscode-java-test")
      (mkExt "vscjava" "vscode-maven")
    ]
    ++ lib.optionals config.hm.languages.haskell [
      (mkExt "haskell" "haskell")
      (mkExt "justusadam" "language-haskell")
    ]
    ++ lib.optionals config.hm.languages.scala [ (mkExt "scalameta" "metals") ]
    ++ lib.optionals config.hm.languages.ocaml [ (mkExt "ocamllabs" "vscode-ocaml-platform") ]
    ++ lib.optionals config.hm.languages.perl [ (mkExt "richterger" "perl") ]
    ++ lib.optionals config.hm.languages.dart [
      (mkExt "dart-code" "dart-code")
      (mkExt "dart-code" "flutter")
    ]
    ++ lib.optionals config.hm.languages.clojure [ (mkExt "betterthantomorrow" "calva") ]
    ++ lib.optionals config.hm.languages.fsharp [ (mkExt "ionide" "ionide-fsharp") ]
    ++ lib.optionals config.hm.languages.lisp [ (mkExt "mattn" "lisp") ]
    ++ lib.optionals config.hm.languages.zig [ (mkExt "ziglang" "vscode-zig") ];

  settings =
    {
      security.workspace.trust.enabled = false;

      nix.enableLanguageServer = true;
      nix.serverPath = "nil";
      alejandra.program = "nixfmt";
      "[nix]" = {
        editor.defaultFormatter = "kamadorueda.alejandra";
        editor.formatOnPaste = true;
        editor.formatOnSave = true;
        editor.formatOnType = true;
      };
      "[json]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
        editor.formatOnSave = true;
      };
      "[jsonc]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
        editor.formatOnSave = true;
      };
      "[toml]" = {
        editor.defaultFormatter = "tamasfe.even-better-toml";
        editor.formatOnSave = true;
      };
      "[yaml]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
        editor.formatOnSave = true;
      };
      "[yml]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
        editor.formatOnSave = true;
      };
      "[shellscript]" = {
        editor.formatOnSave = true;
      };

      markdownlint.config = {
        "MD033" = false; # Inline HTML
        "MD041" = false; # First line in a file should be a top-level heading
        "MD045" = false; # Images should have alternate text
      };

      bashIde.explainshellEndpoint = "http://localhost:5134";
    }
    // lib.optionalAttrs config.hm.languages.java {
      "[java]" = {
        editor.formatOnPaste = true;
        editor.defaultFormatter = "esbenp.prettier-vscode";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.javascript {
      "[javascript]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
        editor.formatOnPaste = true;
        editor.formatOnSave = true;
        editor.formatOnType = true;
      };
      "[typescript]" = {
        editor.formatOnPaste = true;
        editor.defaultFormatter = "esbenp.prettier-vscode";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.csharp {
      "[csharp]" = {
        editor.defaultFormatter = "ms-dotnettools.csharp";
        editor.formatOnSave = true;
        editor.codeActionsOnSave = {
          source.fixAll = "explicit";
          source.organizeImports = "explicit";
        };
      };
    }
    // lib.optionalAttrs config.hm.languages.cpp {
      "[cpp]" = {
        editor.defaultFormatter = "ms-vscode.cpptools";
        editor.formatOnSave = true;
        editor.codeActionsOnSave = {
          source.fixAll = "explicit";
        };
      };
      "[c]" = {
        editor.defaultFormatter = "ms-vscode.cpptools";
        editor.formatOnSave = true;
        editor.codeActionsOnSave = {
          source.fixAll = "explicit";
        };
      };
      "C_Cpp.default.cppStandard" = "c++23";
      "C_Cpp.default.cStandard" = "c23";
      "C_Cpp.default.intelliSenseMode" = "linux-gcc-x64";
    }
    // lib.optionalAttrs config.hm.languages.rust {
      "[rust]" = {
        editor.defaultFormatter = "rust-lang.rust-analyzer";
        editor.formatOnSave = true;
        editor.codeActionsOnSave = {
          source.fixAll = "explicit";
          source.organizeImports = "explicit";
        };
      };
    }
    // lib.optionalAttrs config.hm.languages.lua {
      "[lua]" = {
        editor.defaultFormatter = "sumneko.lua";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.go {
      "[go]" = {
        editor.defaultFormatter = "golang.go";
        editor.formatOnSave = true;
        editor.codeActionsOnSave = {
          source.organizeImports = "explicit";
        };
      };
    }
    // lib.optionalAttrs config.hm.languages.swift {
      "[swift]" = {
        editor.defaultFormatter = "swift-server.swift";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.ruby {
      "[ruby]" = {
        editor.defaultFormatter = "rebornix.ruby";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.php {
      "[php]" = {
        editor.defaultFormatter = "bmewburn.vscode-intelephense-client";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.kotlin {
      "[kotlin]" = {
        editor.defaultFormatter = "fwcd.kotlin";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.elixir {
      "[elixir]" = {
        editor.defaultFormatter = "jakebecker.elixir-ls";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.haskell {
      "[haskell]" = {
        editor.defaultFormatter = "haskell.haskell";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.scala {
      "[scala]" = {
        editor.defaultFormatter = "scalameta.metals";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.ocaml {
      "[ocaml]" = {
        editor.defaultFormatter = "ocamllabs.vscode-ocaml-platform";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.perl {
      "[perl]" = {
        editor.defaultFormatter = "richterger.perl";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.dart {
      "[dart]" = {
        editor.defaultFormatter = "dart-code.dart-code";
        editor.formatOnSave = true;
        editor.codeActionsOnSave = {
          source.fixAll = "explicit";
          source.organizeImports = "explicit";
        };
      };
    }
    // lib.optionalAttrs config.hm.languages.clojure {
      "[clojure]" = {
        editor.defaultFormatter = "betterthantomorrow.calva";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.fsharp {
      "[fsharp]" = {
        editor.defaultFormatter = "ionide.ionide-fsharp";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.lisp {
      "[lisp]" = {
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs config.hm.languages.nim {
      "[nim]" = {
        editor.defaultFormatter = "kosz78.nim";
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs (config.hm.languages.python or false) {
      "[python]" = {
        editor.defaultFormatter = "charliermarsh.ruff";
        editor.codeActionsOnSave = {
          source.fixAll.ruff = "explicit";
          source.organizeImports.ruff = "explicit";
        };
        editor.formatOnSave = true;
      };
    }
    // lib.optionalAttrs (config.hm.languages.html or false) {
      "[html]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
      };
    }
    // lib.optionalAttrs config.hm.languages.zig {
      "[zig]" = {
        editor.defaultFormatter = "ziglang.vscode-zig";
        editor.formatOnSave = true;
        editor.codeActionsOnSave = {
          source.fixAll = "explicit";
        };
      };
      "zig.path" = "zig";
      "zig.zls.path" = "zls";
      "zig.initialSetupDone" = true;
    };
in
{
  config = lib.mkIf config.hm.vscode.enable {
    programs.vscode.profiles.default.extensions = extensions;
    programs.vscode.profiles.default.userSettings = settings;
  };
}
