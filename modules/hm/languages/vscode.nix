{
  pkgsUnstable,
  eulib,
  config,
  lib,
  ...
}:
let
  inherit (config.programs.vscode.package) version;
  mkExt = eulib.mkExt version;
in
{
  config = lib.mkIf config.hm.vscode.enable {
    programs.vscode.profiles.default.extensions =
      (lib.optionals (config.hm.languages.cpp.enable or config.hm.languages.rust.enable
        or config.hm.languages.swift.enable
      ) [ pkgsUnstable.vscode-extensions.vadimcn.vscode-lldb ])
      ++ lib.optionals config.hm.languages.csharp.enable [
        (mkExt "ms-dotnettools" "csharp")
        (mkExt "ms-dotnettools" "vscode-dotnet-runtime")
      ]
      ++ lib.optionals config.hm.languages.cpp.enable [
        (mkExt "ms-vscode" "cmake-tools")
        (mkExt "ms-vscode" "cpptools")
        (mkExt "ms-vscode" "cpptools-extension-pack")
        (mkExt "twxs" "cmake")
      ]
      ++ lib.optionals config.hm.languages.rust.enable [
        (mkExt "fill-labs" "dependi")
        (mkExt "rust-lang" "rust-analyzer")
      ]
      ++ lib.optionals config.hm.languages.lua.enable [
        (mkExt "keyring" "lua")
        (mkExt "sumneko" "lua")
      ]
      ++ lib.optionals config.hm.languages.javascript.enable [
        (mkExt "bradlc" "vscode-tailwindcss")
        (mkExt "christian-kohler" "npm-intellisense")
        (mkExt "denoland" "vscode-deno")
        (mkExt "esbenp" "prettier-vscode")
        (mkExt "ms-vscode" "vscode-typescript-next")
        (mkExt "syler" "sass-indented")
      ]
      ++ lib.optionals config.hm.languages.nim.enable [
        (mkExt "nimLang" "nimlang")
        (mkExt "nimsaem" "nimvscode")
      ]
      ++ lib.optionals config.hm.languages.go.enable [
        (mkExt "golang" "go")
        (mkExt "premparihar" "gotestexplorer")
      ]
      ++ lib.optionals config.hm.languages.swift.enable [
        (mkExt "swift-server" "swift")
        (mkExt "vknabel" "swift-coverage")
      ]
      ++ lib.optionals config.hm.languages.ruby.enable [
        (mkExt "shopify" "ruby-lsp")
        (mkExt "sorbet" "sorbet-vscode-extension")
      ]
      ++ lib.optionals config.hm.languages.python.enable [
        (mkExt "charliermarsh" "ruff")
        (mkExt "ms-python" "debugpy")
        (mkExt "ms-python" "python")
        (mkExt "ms-python" "vscode-pylance")
        (mkExt "ms-toolsai" "jupyter")
      ]
      ++ lib.optionals config.hm.languages.php.enable [
        (mkExt "devsense" "phptools-vscode")
        (mkExt "bmewburn" "vscode-intelephense-client")
        (mkExt "xdebug" "php-debug")
      ]
      ++ lib.optionals config.hm.languages.kotlin.enable [ (mkExt "fwcd" "kotlin") ]
      ++ lib.optionals config.hm.languages.elixir.enable [ (mkExt "jakebecker" "elixir-ls") ]
      ++ lib.optionals config.hm.languages.java.enable [
        (mkExt "oracle" "oracle-java")
        (mkExt "redhat" "java")
        (mkExt "vscjava" "vscode-gradle")
        (mkExt "vscjava" "vscode-java-debug")
        (mkExt "vscjava" "vscode-java-dependency")
        (mkExt "vscjava" "vscode-java-test")
        (mkExt "vscjava" "vscode-maven")
        (mkExt "vscjava" "vscode-spring-initializr")
      ]
      ++ lib.optionals config.hm.languages.haskell.enable [
        (mkExt "haskell" "haskell")
        (mkExt "justusadam" "language-haskell")
      ]
      ++ lib.optionals config.hm.languages.scala.enable [ (mkExt "scalameta" "metals") ]
      ++ lib.optionals config.hm.languages.ocaml.enable [
        (mkExt "ocamllabs" "vscode-ocaml-platform")
      ]
      ++ lib.optionals config.hm.languages.perl.enable [ (mkExt "richterger" "perl") ]
      ++ lib.optionals config.hm.languages.dart.enable [
        (mkExt "dart-code" "dart-code")
        (mkExt "dart-code" "flutter")
      ]
      ++ lib.optionals config.hm.languages.clojure.enable [
        (mkExt "betterthantomorrow" "calva")
      ]
      ++ lib.optionals config.hm.languages.fsharp.enable [ (mkExt "ionide" "ionide-fsharp") ]
      ++ lib.optionals config.hm.languages.lisp.enable [ (mkExt "mattn" "lisp") ]
      ++ lib.optionals config.hm.languages.zig.enable [ (mkExt "ziglang" "vscode-zig") ];

    programs.vscode.profiles.default.settings =
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
        "rubyLsp.customRubyCommand" = "${pkgsUnstable.ruby_3_4}/bin/ruby";
        "rubyLsp.lspPath" = "${pkgsUnstable.rubyPackages.ruby-lsp}/bin/ruby-lsp";
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
      };
  };
}
