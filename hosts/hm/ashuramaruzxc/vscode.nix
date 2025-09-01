{
  pkgs,
  lib,
  euvlok,
  osConfig,
  ...
}:
let
  vscodeSystem = { inherit (osConfig.nixpkgs.hostPlatform) system; };
  inherit (euvlok) mkExt;

  languages = {
    extensions = [
      (mkExt vscodeSystem "james-yu" "latex-workshop")
    ];
    settings = {
      latex-workshop.latex = {
        outDir = "./output";
        recipes = [
          {
            name = "xeLaTeX -> Biber -> xeLaTeX";
            tools = [
              "xelatex"
              "biber"
              "xelatex"
            ];
          }
          {
            name = "xeLaTeX -> pdflatex";
            tools = [
              "xelatex"
              "pdflatex"
            ];
          }
        ];
        tools =
          let
            commonLatexArgs = lib.splitString " " "-synctex=1 -interaction=nonstopmode -file-line-error -shell-escape -output-directory=output %DOC%";
            mkLatexTool = name: command: args: { inherit name command args; };
          in
          [
            (mkLatexTool "xelatex" "xelatex" commonLatexArgs)
            (mkLatexTool "biber" "biber" [
              "--output-directory=output"
              "%DOCFILE%"
            ])
            (mkLatexTool "pdflatex" "pdflatex" commonLatexArgs)
          ];
      };
    };
  };

  flattenAttrs =
    attrs: excludePaths:
    let
      isAttrSet = v: builtins.isAttrs v && !builtins.isList v;
      isExcluded = path: lib.any (excludePath: path == excludePath) excludePaths;

      # Convert nested set to flat dot-notation
      go =
        prefix: set:
        lib.concatMap (
          name:
          let
            value = set.${name};
            newPrefix = if prefix == "" then name else "${prefix}.${name}";
          in
          if isExcluded newPrefix then
            [
              {
                name = newPrefix;
                value = value;
              }
            ]
          else if isAttrSet value then
            go newPrefix value
          else
            [
              {
                name = newPrefix;
                value = value;
              }
            ]
        ) (builtins.attrNames set);
    in
    builtins.listToAttrs (go "" attrs);

  mergeFrom =
    let
      modules = [
        languages
      ];
      excludePaths = [
        "[javascript]"
        "[nix]"
        "[typescript]"
      ];
    in
    p:
    if p == "extensions" then
      lib.concatLists (map (module: module.${p}) modules)
    else
      flattenAttrs (lib.foldl' (
        acc: module: lib.recursiveUpdate acc module.${p}
      ) { } modules) excludePaths;
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
          "languageServer" = "Pylance";
          "editor.codeActionsOnSave" = {
            "source.fixAll.ruff" = "explicit";
            "source.organizeImports.ruff" = "explicit";
          };
        };
        "isort.args" = [
          "--profile"
          "black"
        ];
        "ruff.format.args" = [
          "--line-length=120"
        ];

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
      }
      // mergeFrom "settings";
      extensions = [
        ## -- Programming languages/lsp support -- ##
        (mkExt vscodeSystem "josetr" "cmake-language-support-vscode")
        (mkExt vscodeSystem "scala-lang" "scala")
        (mkExt vscodeSystem "mathiasfrohlich" "kotlin")
        (mkExt vscodeSystem "ms-azuretools" "vscode-docker")
        (mkExt vscodeSystem "ms-kubernetes-tools" "vscode-kubernetes-tools")
        (mkExt vscodeSystem "dotjoshjohnson" "xml")
        (mkExt vscodeSystem "graphql" "vscode-graphql")
        (mkExt vscodeSystem "graphql" "vscode-graphql-syntax")
        (mkExt vscodeSystem "pinage404" "bash-extension-pack")

        # Gay
        (mkExt vscodeSystem "biud436" "rgss-script-compiler") # VX
        (mkExt vscodeSystem "mjmcreativeworksandidea" "rmmvpluginsnippet") # MV
        (mkExt vscodeSystem "snowszn" "rgss-script-editor")
        ## -- Programming languages/lsp support -- ##

        ## -- git -- ##
        (mkExt vscodeSystem "github" "vscode-github-actions")
        ## -- Misc Utils -- ##
        (mkExt vscodeSystem "njpwerner" "autodocstring")
        (mkExt vscodeSystem "mikestead" "dotenv")
        (mkExt vscodeSystem "humao" "rest-client") # Alternative REST client
        (mkExt vscodeSystem "rangav" "vscode-thunder-client") # Thunder Client
        ## -- Misc Utils -- ##

        ## -- C/C++ Utils -- ##
        (mkExt vscodeSystem "formulahendry" "code-runner")
        (mkExt vscodeSystem "danielpinto8zz6" "c-cpp-compile-run")
        (mkExt vscodeSystem "ms-vscode" "makefile-tools")
        (mkExt vscodeSystem "cschlosser" "doxdocgen")
        (mkExt vscodeSystem "jeff-hykin" "better-cpp-syntax") # Better syntax highlighting
        ## -- C/C++ Utils -- ##

        ## -- Python Utils -- ##
        # Fuck you sarco
        (mkExt vscodeSystem "batisteo" "vscode-django")
        (mkExt vscodeSystem "donjayamanne" "python-environment-manager")
        (mkExt vscodeSystem "kaih2o" "python-resource-monitor")
        (mkExt vscodeSystem "kevinrose" "vsc-python-indent")
        (mkExt vscodeSystem "ms-python" "black-formatter")
        (mkExt vscodeSystem "ms-python" "flake8")
        (mkExt vscodeSystem "ms-python" "gather")
        (mkExt vscodeSystem "ms-python" "isort")
        (mkExt vscodeSystem "ms-python" "mypy-type-checker")
        (mkExt vscodeSystem "ms-python" "pylint")
        (mkExt vscodeSystem "wholroyd" "jinja")
        ## -- Python Utils -- ##

        ## -- JavaScript/Typescript Utils -- ##
        (mkExt vscodeSystem "angular" "ng-template")
        (mkExt vscodeSystem "dsznajder" "es7-react-js-snippets")
        (mkExt vscodeSystem "ecmel" "vscode-html-css")
        (mkExt vscodeSystem "formulahendry" "auto-close-tag")
        (mkExt vscodeSystem "formulahendry" "auto-rename-tag")
        (mkExt vscodeSystem "hollowtree" "vue-snippets")
        (mkExt vscodeSystem "jasonnutter" "search-node-modules")
        (mkExt vscodeSystem "johnpapa" "angular2")
        (mkExt vscodeSystem "msjsdiag" "vscode-react-native")
        (mkExt vscodeSystem "octref" "vetur")
        (mkExt vscodeSystem "prisma" "prisma")
        (mkExt vscodeSystem "ritwickdey" "liveserver")
        (mkExt vscodeSystem "steoates" "autoimport")
        (mkExt vscodeSystem "vue" "volar")
        (mkExt vscodeSystem "wix" "vscode-import-cost")
        (mkExt vscodeSystem "styled-components" "vscode-styled-components") # styled-components
        (mkExt vscodeSystem "graphql" "vscode-graphql-execution") # GraphQL execution
        ## -- JavaScript/Typescript Utils -- ##

        ## -- Vscode specific -- ##
        (mkExt vscodeSystem "aaron-bond" "better-comments")
        (mkExt vscodeSystem "christian-kohler" "path-intellisense")
        (mkExt vscodeSystem "donjayamanne" "githistory")
        (mkExt vscodeSystem "donjayamanne" "git-extension-pack")
        (mkExt vscodeSystem "eamodio" "gitlens")
        (mkExt vscodeSystem "ms-vscode" "hexeditor")
        (mkExt vscodeSystem "ms-vsliveshare" "vsliveshare")
        (mkExt vscodeSystem "visualstudioexptteam" "intellicode-api-usage-examples")
        ## -- Vscode specific -- ##

        ## -- Dictionary/Languages support -- ##
        pkgs.vscode-extensions.ms-ceintl.vscode-language-pack-ja
        ## -- Dictionary/Languages support -- ##
      ]
      ++ mergeFrom "extensions";
    };
  };
}
