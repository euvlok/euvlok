{
  pkgs,
  config,
  lib,
  ...
}:
let
  extensionStrings =
    (lib.optionals (config.hm.languages.cpp.enable or config.hm.languages.rust.enable
      or config.hm.languages.swift.enable
    ) [ "vadimcn.vscode-lldb" ])
    ++ lib.optionals config.hm.languages.csharp.enable [
      "ms-dotnettools.csharp"
      "ms-dotnettools.csdevkit"
      "ms-dotnettools.vscode-dotnet-runtime"
    ]
    ++ lib.optionals config.hm.languages.cpp.enable [
      "ms-vscode.cmake-tools"
      "ms-vscode.cpptools"
      "ms-vscode.cpptools-extension-pack"
      "twxs.cmake"
    ]
    ++ lib.optionals config.hm.languages.rust.enable [
      "fill-labs.dependi"
      "rust-lang.rust-analyzer"
    ]
    ++ lib.optionals config.hm.languages.lua.enable [
      "keyring.lua"
      "sumneko.lua"
    ]
    ++ lib.optionals config.hm.languages.javascript.enable [
      "bradlc.vscode-tailwindcss"
      "christian-kohler.npm-intellisense"
      "denoland.vscode-deno"
      "esbenp.prettier-vscode"
      "ms-vscode.vscode-typescript-next"
      "syler.sass-indented"
    ]
    ++ lib.optionals config.hm.languages.nim.enable [
      "nimLang.nimlang"
      "nimsaem.nimvscode"
    ]
    ++ lib.optionals config.hm.languages.go.enable [
      "golang.go"
      "premparihar.gotestexplorer"
    ]
    ++ lib.optionals config.hm.languages.swift.enable [
      "swift-server.swift"
      "vknabel.swift-coverage"
    ]
    ++ lib.optionals config.hm.languages.ruby.enable [
      "shopify.ruby-lsp"
      "sorbet.sorbet-vscode-extension"
    ]
    ++ lib.optionals config.hm.languages.python.enable [
      "charliermarsh.ruff"
      "ms-python.debugpy"
      "ms-python.python"
      "ms-python.vscode-pylance"
      "ms-toolsai.jupyter"
    ]
    ++ lib.optionals config.hm.languages.php.enable [
      "devsense.phptools-vscode"
      "bmewburn.vscode-intelephense-client"
      "xdebug.php-debug"
    ]
    ++ lib.optionals config.hm.languages.kotlin.enable [ "fwcd.kotlin" ]
    ++ lib.optionals config.hm.languages.elixir.enable [ "jakebecker.elixir-ls" ]
    ++ lib.optionals config.hm.languages.java.enable [
      "oracle.oracle-java"
      "redhat.java"
      "vscjava.vscode-gradle"
      "vscjava.vscode-java-debug"
      "vscjava.vscode-java-dependency"
      "vscjava.vscode-java-test"
      "vscjava.vscode-maven"
      "vscjava.vscode-spring-initializr"
    ]
    ++ lib.optionals config.hm.languages.haskell.enable [
      "haskell.haskell"
      "justusadam.language-haskell"
    ]
    ++ lib.optionals config.hm.languages.scala.enable [ "scalameta.metals" ]
    ++ lib.optionals config.hm.languages.ocaml.enable [
      "ocamllabs.vscode-ocaml-platform"
    ]
    ++ lib.optionals config.hm.languages.perl.enable [ "richterger.perl" ]
    ++ lib.optionals config.hm.languages.dart.enable [
      "dart-code.dart-code"
      "dart-code.flutter"
    ]
    ++ lib.optionals config.hm.languages.clojure.enable [
      "betterthantomorrow.calva"
    ]
    ++ lib.optionals config.hm.languages.fsharp.enable [ "ionide.ionide-fsharp" ]
    ++ lib.optionals config.hm.languages.lisp.enable [ "mattn.lisp" ]
    ++ lib.optionals config.hm.languages.zig.enable [ "ziglang.vscode-zig" ];
in
{
  config = lib.mkIf config.hm.vscode.enable {
    programs.vscode.profiles.default.extensions =
      pkgs.nix4vscode.forVscodeVersion config.programs.vscode.package.version extensionStrings;

    programs.vscode.profiles.default.userSettings =
      lib.optionalAttrs config.hm.languages.java.enable {
        "[java]" = {
          editor.formatOnPaste = true;
          editor.defaultFormatter = "esbenp.prettier-vscode";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.javascript.enable {
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
      // lib.optionalAttrs config.hm.languages.csharp.enable {
        "[csharp]" = {
          editor.defaultFormatter = "ms-dotnettools.csharp";
          editor.formatOnSave = true;
          editor.codeActionsOnSave = {
            source.fixAll = "explicit";
            source.organizeImports = "explicit";
          };
        };
      }
      // lib.optionalAttrs config.hm.languages.cpp.enable {
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
      // lib.optionalAttrs config.hm.languages.rust.enable {
        "[rust]" = {
          editor.defaultFormatter = "rust-lang.rust-analyzer";
          editor.formatOnSave = true;
          editor.codeActionsOnSave = {
            source.fixAll = "explicit";
            source.organizeImports = "explicit";
          };
        };
      }
      // lib.optionalAttrs config.hm.languages.lua.enable {
        "[lua]" = {
          editor.defaultFormatter = "sumneko.lua";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.go.enable {
        "[go]" = {
          editor.defaultFormatter = "golang.go";
          editor.formatOnSave = true;
          editor.codeActionsOnSave = {
            source.organizeImports = "explicit";
          };
        };
      }
      // lib.optionalAttrs config.hm.languages.swift.enable {
        "[swift]" = {
          editor.defaultFormatter = "swift-server.swift";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.ruby.enable {
        "rubyLsp.bundleGemfile" = "";
        "rubyLsp.customRubyCommand" = "${pkgs.unstable.ruby_3_4}/bin/ruby";
        "rubyLsp.lspPath" = "${pkgs.unstable.rubyPackages.ruby-lsp}/bin/ruby-lsp";
        "rubyLsp.pullDiagnosticsOn" = "save";
        "rubyLsp.rubyVersionManager" = "none";
        "[ruby]" = {
          editor.defaultFormatter = "shopify.ruby-lsp";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.php.enable {
        "[php]" = {
          editor.defaultFormatter = "bmewburn.vscode-intelephense-client";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.kotlin.enable {
        "[kotlin]" = {
          editor.defaultFormatter = "fwcd.kotlin";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.elixir.enable {
        "[elixir]" = {
          editor.defaultFormatter = "jakebecker.elixir-ls";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.haskell.enable {
        "[haskell]" = {
          editor.defaultFormatter = "haskell.haskell";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.scala.enable {
        "[scala]" = {
          editor.defaultFormatter = "scalameta.metals";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.ocaml.enable {
        "[ocaml]" = {
          editor.defaultFormatter = "ocamllabs.vscode-ocaml-platform";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.perl.enable {
        "[perl]" = {
          editor.defaultFormatter = "richterger.perl";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.dart.enable {
        "[dart]" = {
          editor.defaultFormatter = "dart-code.dart-code";
          editor.formatOnSave = true;
          editor.codeActionsOnSave = {
            source.fixAll = "explicit";
            source.organizeImports = "explicit";
          };
        };
      }
      // lib.optionalAttrs config.hm.languages.clojure.enable {
        "[clojure]" = {
          editor.defaultFormatter = "betterthantomorrow.calva";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.fsharp.enable {
        "[fsharp]" = {
          editor.defaultFormatter = "ionide.ionide-fsharp";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.lisp.enable {
        "[lisp]" = {
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs config.hm.languages.nim.enable {
        "[nim]" = {
          editor.defaultFormatter = "kosz78.nim";
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs (config.hm.languages.python.enable or false) {
        "[python]" = {
          editor.defaultFormatter = "charliermarsh.ruff";
          editor.codeActionsOnSave = {
            source.fixAll.ruff = "explicit";
            source.organizeImports.ruff = "explicit";
          };
          editor.formatOnSave = true;
        };
      }
      // lib.optionalAttrs (config.hm.languages.html.enable or false) {
        "[html]" = {
          editor.defaultFormatter = "esbenp.prettier-vscode";
        };
      }
      // lib.optionalAttrs config.hm.languages.zig.enable {
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
      }
      // {
        "[toml]" = {
          editor.defaultFormatter = "tamasfe.even-better-toml";
          editor.formatOnSave = true;
        };
      };
  };
}
