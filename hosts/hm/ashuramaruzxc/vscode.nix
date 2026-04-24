{ pkgs, config, ... }:
let
  extensionStrings = [
    ## -- Programming languages/lsp support -- ##
    "josetr.cmake-language-support-vscode"
    "ms-azuretools.vscode-docker"
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "graphql.vscode-graphql"
    "graphql.vscode-graphql-syntax"

    # Gay
    "biud436.rgss-script-compiler" # VX
    "mjmcreativeworksandidea.rmmvpluginsnippet" # MV
    "snowszn.rgss-script-editor"
    ## -- Programming languages/lsp support -- ##

    ## -- git -- ##
    "github.vscode-github-actions"
    ## -- Misc Utils -- ##
    "njpwerner.autodocstring"
    "mikestead.dotenv"
    "rangav.vscode-thunder-client" # Thunder Client
    ## -- Misc Utils -- ##

    ## -- C/C++ Utils -- ##
    "ms-vscode.makefile-tools"
    "cschlosser.doxdocgen"
    "jeff-hykin.better-cpp-syntax" # Better syntax highlighting
    ## -- C/C++ Utils -- ##

    ## -- Python Utils -- ##
    "batisteo.vscode-django"
    "donjayamanne.python-environment-manager"
    "kaih2o.python-resource-monitor"
    "kevinrose.vsc-python-indent"
    "ms-python.black-formatter"
    "ms-python.flake8"
    "ms-python.gather"
    "ms-python.isort"
    "ms-python.mypy-type-checker"
    "ms-python.pylint"
    "wholroyd.jinja"
    ## -- Python Utils -- ##

    ## -- JavaScript/Typescript Utils -- ##
    "angular.ng-template"
    "ecmel.vscode-html-css"
    "formulahendry.auto-close-tag"
    "formulahendry.auto-rename-tag"
    "jasonnutter.search-node-modules"
    "johnpapa.angular2"
    "msjsdiag.vscode-react-native"
    "prisma.prisma"
    "ritwickdey.liveserver"
    "vue.volar"
    "wix.vscode-import-cost"
    "styled-components.vscode-styled-components" # styled-components
    "graphql.vscode-graphql-execution" # GraphQL execution
    ## -- JavaScript/Typescript Utils -- ##

    ## -- Vscode specific -- ##
    "aaron-bond.better-comments"
    "christian-kohler.path-intellisense"
    "eamodio.gitlens"
    "ms-vscode.hexeditor"
    "ms-vsliveshare.vsliveshare"
    ## -- Vscode specific -- ##

    ## -- Dictionary/Languages support -- ##
    "ms-ceintl.vscode-language-pack-ja"
    ## -- Dictionary/Languages support -- ##

    ## -- Slop -- ##
    "saoudrizwan.claude-dev"
    # "openai.chatgpt"
    ## -- Slop -- ##
  ];
in
{
  programs.vscode = {
    profiles.default = {
      userSettings = {
        "search.followSymlinks" = false;
        "files.autoSave" = "afterDelay";

        # Editor basics
        "editor.bracketPairColorization.enabled" = true;
        "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
        "editor.cursorBlinking" = "blink";
        "editor.cursorStyle" = "line";
        "editor.fontFamily" = "'MesloLGL Nerd Font'";
        "editor.fontSize" = 19;
        "editor.formatOnSave" = true;
        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "selection";
        "editor.semanticHighlighting.enabled" = true;
        "editor.tabSize" = 2;
        "editor.wordWrap" = "on";

        "editor.quickSuggestions" = {
          "other" = "on";
          "comments" = "on";
          "strings" = "off";
        };

        # Diff
        "diffEditor.maxFileSize" = 0;

        # Terminal
        "terminal.integrated.minimumContrastRatio" = 1;
        "terminal.integrated.fontFamily" = "'Hack Nerd Font'";
        "terminal.integrated.cursorStyle" = "line";
        "terminal.integrated.cursorBlinking" = true;
        "terminal.integrated.inheritEnv" = true;

        # Workbench
        "workbench.editor.showIcons" = true;
        "workbench.sideBar.location" = "right";
        "workbench.secondarySideBar.defaultVisibility" = "hidden";
        "window.titleBarStyle" = "native";
        "telemetry.telemetryLevel" = "off";

        # Unicode highlight exceptions
        "editor.unicodeHighlight.allowedLocales" = {
          "ja" = true;
          "　" = true;
        };

        # Python
        "[python]" = {
          "editor.defaultFormatter" = "charliermarsh.ruff";
          "editor.formatOnSave" = true;
          "editor.insertSpaces" = true;
          "editor.codeActionsOnSave" = {
            "source.fixAll.ruff" = "explicit";
            "source.organizeImports.ruff" = "explicit";
          };
        };
        "isort.args" = [
          "--profile"
          "black"
        ];
        "ruff.nativeServer" = "on";
        "ruff.lineLength" = 120;

        # JS / TS
        "javascript.suggest.paths" = false;
        "typescript.suggest.paths" = false;

        "[javascript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.formatOnPaste" = true;
          "editor.formatOnSave" = true;
          "editor.formatOnType" = true;
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.formatOnPaste" = true;
          "editor.formatOnSave" = true;
        };

        # C / C++
        "[cpp]" = {
          "editor.defaultFormatter" = "ms-vscode.cpptools";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.fixAll" = "explicit";
          };
        };
        "[c]" = {
          "editor.defaultFormatter" = "ms-vscode.cpptools";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.fixAll" = "explicit";
          };
        };

        "C_Cpp.default.cppStandard" = "c++23";
        "C_Cpp.default.cStandard" = "c23";
        "C_Cpp.default.intelliSenseMode" = "linux-gcc-x64";

        # C#
        "[csharp]" = {
          "editor.defaultFormatter" = "ms-dotnettools.csharp";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.fixAll" = "explicit";
            "source.organizeImports" = "explicit";
          };
        };

        # Dart
        "[dart]" = {
          "editor.defaultFormatter" = "dart-code.dart-code";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.fixAll" = "explicit";
            "source.organizeImports" = "explicit";
          };
        };

        # Go
        "[go]" = {
          "editor.defaultFormatter" = "golang.go";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.organizeImports" = "explicit";
          };
        };

        # Haskell
        "[haskell]" = {
          "editor.defaultFormatter" = "haskell.haskell";
          "editor.formatOnSave" = true;
        };

        # Java
        "[java]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.formatOnPaste" = true;
          "editor.formatOnSave" = true;
        };

        # Kotlin
        "[kotlin]" = {
          "editor.defaultFormatter" = "fwcd.kotlin";
          "editor.formatOnSave" = true;
        };

        # Lisp
        "[lisp]" = {
          "editor.formatOnSave" = true;
        };

        # Lua
        "[lua]" = {
          "editor.defaultFormatter" = "sumneko.lua";
          "editor.formatOnSave" = true;
        };

        # Ruby
        "[ruby]" = {
          "editor.defaultFormatter" = "shopify.ruby-lsp";
          "editor.formatOnSave" = true;
        };

        # Rust
        "[rust]" = {
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.fixAll" = "explicit";
            "source.organizeImports" = "explicit";
          };
        };
      };
      extensions = pkgs.nix4vscode.forVscodeVersion config.programs.vscode.package.version extensionStrings;
    };
  };
}
