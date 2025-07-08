{
  pkgs,
  lib,
  euvlok,
  config,
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

  themes = {
    extensions = [
      (mkExt vscodeSystem "catppuccin" "catppuccin-vsc-icons")
      (mkExt vscodeSystem "catppuccin" "catppuccin-vsc")
    ];
    settings = {
      workbench.iconTheme = "catppuccin-${config.catppuccin.flavor}";
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
        themes
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
        "diffEditor.maxFileSize" = 0;
        # Terminal
        "terminal.integrated.minimumContrastRatio" = 1;
        "terminal.integrated.fontFamily" = "'Hack Nerd Font'";
        "terminal.integrated.cursorStyle" = "line";
        "terminal.integrated.cursorBlinking" = true;
        "terminal.integrated.inheritEnv" = true;

        "workbench.editor.showIcons" = true;
        "workbench.sideBar.location" = "right";
        "window.titleBarStyle" = "native";
        "telemetry.telemetryLevel" = "off";
        "editor.unicodeHighlight.allowedLocales" = {
          "ja" = true;
          "　" = true;
        };

        # Python
        "[python]" = {
          "editor.defaultFormatter" = "ms-python.black-formatter";
          "editor.formatOnSave" = true;
          "editor.insertSpaces" = true;
          "languageServer" = "Pylance";
          "formatting.provider" = "black";
          "formatting.blackArgs" = [
            "--line-length"
            "120"
          ];
        };
        "isort.args" = [
          "--profile"
          "black"
        ];
        #JS
        "javascript.suggest.paths" = false;
        "typescript.suggest.paths" = false;
      } // mergeFrom "settings";
      extensions = [
        ## -- Programming languages/lsp support -- ##
        (mkExt vscodeSystem "ms-vscode" "cpptools-extension-pack")
        (mkExt vscodeSystem "josetr" "cmake-language-support-vscode")
        (mkExt vscodeSystem "rust-lang" "rust-analyzer")
        (mkExt vscodeSystem "golang" "go")
        (mkExt vscodeSystem "scala-lang" "scala")
        (mkExt vscodeSystem "mathiasfrohlich" "kotlin")
        (mkExt vscodeSystem "fwcd" "kotlin")
        (mkExt vscodeSystem "shopify" "ruby-lsp")
        (mkExt vscodeSystem "dart-code" "flutter")
        (mkExt vscodeSystem "ms-azuretools" "vscode-docker")
        (mkExt vscodeSystem "ms-kubernetes-tools" "vscode-kubernetes-tools")
        (mkExt vscodeSystem "yzhang" "markdown-all-in-one")
        (mkExt vscodeSystem "redhat" "vscode-yaml")
        (mkExt vscodeSystem "dotjoshjohnson" "xml")
        (mkExt vscodeSystem "tamasfe" "even-better-toml")
        (mkExt vscodeSystem "editorconfig" "editorconfig")
        (mkExt vscodeSystem "graphql" "vscode-graphql")
        (mkExt vscodeSystem "graphql" "vscode-graphql-syntax")
        (mkExt vscodeSystem "bbenoist" "nix")
        (mkExt vscodeSystem "pinage404" "bash-extension-pack")
        ## -- Programming languages/lsp support -- ##
        ## -- git -- ##
        pkgs.vscode-extensions.github.vscode-pull-request-github
        (mkExt vscodeSystem "github" "vscode-github-actions")
        ## -- Misc Utils -- ##
        (mkExt vscodeSystem "esbenp" "prettier-vscode")
        (mkExt vscodeSystem "davidanson" "vscode-markdownlint")
        (mkExt vscodeSystem "njpwerner" "autodocstring")
        (mkExt vscodeSystem "mikestead" "dotenv")
        (mkExt vscodeSystem "humao" "rest-client")
        ## -- Misc Utils -- ##

        ## -- Nix Utils -- ##
        (mkExt vscodeSystem "jnoortheen" "nix-ide")
        (mkExt vscodeSystem "mkhl" "direnv")
        (mkExt vscodeSystem "rubymaniac" "vscode-direnv")
        (mkExt vscodeSystem "brettm12345" "nixfmt-vscode")
        ## -- Nix Utils -- ##

        ## -- Java Utils -- ##
        (mkExt vscodeSystem "redhat" "java")
        (mkExt vscodeSystem "vscjava" "vscode-gradle")
        (mkExt vscodeSystem "vscjava" "vscode-java-debug")
        (mkExt vscodeSystem "vscjava" "vscode-java-pack")
        ## -- Java Utils -- ##

        ## -- C/C++ Utils -- ##
        (mkExt vscodeSystem "ms-vscode" "cpptools-extension-pack")
        (mkExt vscodeSystem "formulahendry" "code-runner")
        (mkExt vscodeSystem "danielpinto8zz6" "c-cpp-compile-run")
        (mkExt vscodeSystem "ms-vscode" "makefile-tools")
        (mkExt vscodeSystem "cschlosser" "doxdocgen")
        ## -- C/C++ Utils -- ##

        ## -- Dotnet Utils -- ##
        (mkExt vscodeSystem "ms-dotnettools" "vscode-dotnet-pack")
        ## -- Dotnet Utils -- ##

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
        (mkExt vscodeSystem "ms-python" "debugpy")
        (mkExt vscodeSystem "ms-python" "mypy-type-checker")
        (mkExt vscodeSystem "ms-python" "pylint")
        (mkExt vscodeSystem "wholroyd" "jinja")
        (mkExt vscodeSystem "ms-python" "python")
        (mkExt vscodeSystem "ms-toolsai" "jupyter")
        ## -- Python Utils -- ##

        ## -- JavaScript/Typescript Utils -- ##
        (mkExt vscodeSystem "angular" "ng-template")
        (mkExt vscodeSystem "bradlc" "vscode-tailwindcss")
        (mkExt vscodeSystem "christian-kohler" "npm-intellisense")
        (mkExt vscodeSystem "dbaeumer" "vscode-eslint")
        (mkExt vscodeSystem "dsznajder" "es7-react-js-snippets")
        (mkExt vscodeSystem "ecmel" "vscode-html-css")
        (mkExt vscodeSystem "firefox-devtools" "vscode-firefox-debug")
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
        (mkExt vscodeSystem "visualstudioexptteam" "vscodeintellicode")
        pkgs.vscode-extensions.github.vscode-pull-request-github
        ## -- Vscode specific -- ##

        ## -- Dictionary/Languages support -- ##
        pkgs.vscode-extensions.ms-ceintl.vscode-language-pack-ja
        ## -- Dictionary/Languages support -- ##
      ] ++ mergeFrom "extensions";
    };
  };
  home.sessionVariables = {
    GO_PATH = "${config.home.homeDirectory}/.go";
  };
}
