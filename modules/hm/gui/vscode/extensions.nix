{
  pkgs,
  lib,
  config,
  osConfig,
  euvlok,
  ...
}:
let
  vscodeSystem = { inherit (osConfig.nixpkgs.hostPlatform) system; };
  inherit (euvlok) mkExt;

  extensions =
    [
      # Nix
      (mkExt vscodeSystem "bbenoist" "nix")
      (mkExt vscodeSystem "jnoortheen" "nix-ide")
      (mkExt vscodeSystem "kamadorueda" "alejandra")

      # Shells
      (mkExt vscodeSystem "bmalehorn" "shell-syntax")
      (mkExt vscodeSystem "mads-hartmann" "bash-ide-vscode")
      (mkExt vscodeSystem "rogalmic" "bash-debug")
      (mkExt vscodeSystem "timonwong" "shellcheck")

      # Code Quality
      (mkExt vscodeSystem "streetsidesoftware" "code-spell-checker")
      (mkExt vscodeSystem "usernamehw" "errorlens")

      # Markup languages
      (mkExt vscodeSystem "davidanson" "vscode-markdownlint")
      (mkExt vscodeSystem "redhat" "vscode-xml")
      (mkExt vscodeSystem "redhat" "vscode-yaml")
      (mkExt vscodeSystem "tamasfe" "even-better-toml")
      (mkExt vscodeSystem "yzhang" "markdown-all-in-one")
      (mkExt vscodeSystem "zainchen" "json")

      # Programming Languages
      (mkExt vscodeSystem "dbaeumer" "vscode-eslint")
      (mkExt vscodeSystem "mgmcdermott" "vscode-language-babel")

      # Misc
      (mkExt vscodeSystem "editorconfig" "editorconfig")
      (mkExt vscodeSystem "oderwat" "indent-rainbow")
      (mkExt vscodeSystem "visualstudioexptteam" "vscodeintellicode")
    ]
    ++ lib.optionals config.programs.direnv.enable [ (mkExt vscodeSystem "mkhl" "direnv") ]
    ++ lib.optionals config.programs.fish.enable [ (mkExt vscodeSystem "bmalehorn" "vscode-fish") ]
    ++ lib.optionals config.programs.nushell.enable [
      (mkExt vscodeSystem "thenuprojectcontributors" "vscode-nushell-lang")
    ]

    # Language-specific extensions
    ++ (lib.optionals (config.hm.languages.cpp or config.hm.languages.rust or config.hm.languages.swift
    ) [ (mkExt "vadimcn" "vscode-lldb") ])
    ++ lib.optionals config.hm.languages.csharp [
      (mkExt vscodeSystem "ms-dotnettools" "csharp")
      (mkExt vscodeSystem "ms-dotnettools" "vscode-dotnet-runtime")
    ]
    ++ lib.optionals config.hm.languages.cpp [
      (mkExt vscodeSystem "ms-vscode" "cmake-tools")
      (mkExt vscodeSystem "ms-vscode" "cpptools")
      (mkExt vscodeSystem "ms-vscode" "cpptools-extension-pack")
      (mkExt vscodeSystem "twxs" "cmake")
    ]
    ++ lib.optionals config.hm.languages.rust [
      (mkExt vscodeSystem "fill-labs" "dependi")
      (mkExt vscodeSystem "rust-lang" "rust-analyzer")
    ]
    ++ lib.optionals config.hm.languages.lua [
      (mkExt vscodeSystem "keyring" "lua")
      (mkExt vscodeSystem "sumneko" "lua")
    ]
    ++ lib.optionals config.hm.languages.javascript [
      (mkExt vscodeSystem "bradlc" "vscode-tailwindcss")
      (mkExt vscodeSystem "christian-kohler" "npm-intellisense")
      (mkExt vscodeSystem "denoland" "vscode-deno")
      (mkExt vscodeSystem "esbenp" "prettier-vscode")
      (mkExt vscodeSystem "esbenp" "prettier-vscode")
      (mkExt vscodeSystem "ms-vscode" "vscode-typescript-next")
      (mkExt vscodeSystem "syler" "sass-indented")
    ]
    ++ lib.optionals config.hm.languages.nim [
      (mkExt vscodeSystem "nimLang" "nimlang")
      (mkExt vscodeSystem "nimsaem" "nimvscode")
    ]
    ++ lib.optionals config.hm.languages.go [
      (mkExt vscodeSystem "golang" "go")
      (mkExt vscodeSystem "premparihar" "gotestexplorer")
    ]
    ++ lib.optionals config.hm.languages.swift [
      (mkExt vscodeSystem "swift-server" "swift")
      (mkExt vscodeSystem "vknabel" "swift-coverage")
    ]
    ++ lib.optionals config.hm.languages.ruby [
      (mkExt vscodeSystem "rebornix" "ruby")
      (mkExt vscodeSystem "shopify" "ruby-lsp")
      (mkExt vscodeSystem "sorbet" "sorbet-vscode-extension")
      (mkExt vscodeSystem "wingrunr21" "vscode-ruby")
    ]
    ++ lib.optionals config.hm.languages.python [
      (mkExt vscodeSystem "charliermarsh" "ruff")
      (mkExt vscodeSystem "ms-python" "debugpy")
      (mkExt vscodeSystem "ms-python" "python")
      (mkExt vscodeSystem "ms-python" "vscode-pylance")
      (mkExt vscodeSystem "ms-toolsai" "jupyter")
    ]
    ++ lib.optionals config.hm.languages.php [
      (mkExt vscodeSystem "devsense" "phptools-vscode")
      (mkExt vscodeSystem "bmewburn" "vscode-intelephense-client")
      (mkExt vscodeSystem "xdebug" "php-debug")
    ]
    ++ lib.optionals config.hm.languages.kotlin [ (mkExt vscodeSystem "fwcd" "kotlin") ]
    ++ lib.optionals config.hm.languages.elixir [ (mkExt vscodeSystem "jakebecker" "elixir-ls") ]
    ++ lib.optionals config.hm.languages.java [
      (mkExt vscodeSystem "oracle" "oracle-java")
      (mkExt vscodeSystem "redhat" "java")
      (mkExt vscodeSystem "vscjava" "vscode-gradle")
      (mkExt vscodeSystem "vscjava" "vscode-java-debug")
      (mkExt vscodeSystem "vscjava" "vscode-java-dependency")
      (mkExt vscodeSystem "vscjava" "vscode-java-test")
      (mkExt vscodeSystem "vscjava" "vscode-maven")
    ]
    ++ lib.optionals config.hm.languages.haskell [
      (mkExt vscodeSystem "haskell" "haskell")
      (mkExt vscodeSystem "justusadam" "language-haskell")
    ]
    ++ lib.optionals config.hm.languages.scala [ (mkExt vscodeSystem "scalameta" "metals") ]
    ++ lib.optionals config.hm.languages.ocaml [
      (mkExt vscodeSystem "ocamllabs" "vscode-ocaml-platform")
    ]
    ++ lib.optionals config.hm.languages.perl [ (mkExt vscodeSystem "richterger" "perl") ]
    ++ lib.optionals config.hm.languages.dart [
      (mkExt vscodeSystem "dart-code" "dart-code")
      (mkExt vscodeSystem "dart-code" "flutter")
    ]
    ++ lib.optionals config.hm.languages.clojure [ (mkExt vscodeSystem "betterthantomorrow" "calva") ]
    ++ lib.optionals config.hm.languages.fsharp [ (mkExt vscodeSystem "ionide" "ionide-fsharp") ]
    ++ lib.optionals config.hm.languages.lisp [ (mkExt vscodeSystem "mattn" "lisp") ]
    ++ lib.optionals config.hm.languages.zig [ (mkExt vscodeSystem "ziglang" "vscode-zig") ];

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
