{
  inputs,
  osConfig,
  lib,
  config,
  pkgs,
  ...
}:
let
  mkExt =
    (import ../../../modules/hm/gui/vscode/lib.nix {
      inherit
        inputs
        osConfig
        pkgs
        ;
    }).mkExt;
  inherit
    (inputs.nix-vscode-extensions.extensions.${osConfig.nixpkgs.hostPlatform.system}.forVSCodeVersion
      pkgs.vscode.version
    )
    vscode-marketplace
    ;
  languages = {
    extensions = [
      (mkExt "james-yu" "latex-workshop")
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
      (mkExt "catppuccin" "catppuccin-vsc-icons")
      (mkExt "catppuccin" "catppuccin-vsc")
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
        (mkExt "ms-vscode" "cpptools-extension-pack")
        (mkExt "josetr" "cmake-language-support-vscode")
        (mkExt "rust-lang" "rust-analyzer")
        (mkExt "golang" "go")
        (mkExt "scala-lang" "scala")
        (mkExt "mathiasfrohlich" "kotlin")
        (mkExt "fwcd" "kotlin")
        (mkExt "shopify" "ruby-lsp")
        (mkExt "dart-code" "flutter")
        (mkExt "ms-azuretools" "vscode-docker")
        (mkExt "ms-kubernetes-tools" "vscode-kubernetes-tools")
        (mkExt "yzhang" "markdown-all-in-one")
        (mkExt "redhat" "vscode-yaml")
        (mkExt "dotjoshjohnson" "xml")
        (mkExt "tamasfe" "even-better-toml")
        (mkExt "editorconfig" "editorconfig")
        (mkExt "graphql" "vscode-graphql")
        (mkExt "graphql" "vscode-graphql-syntax")
        (mkExt "bbenoist" "nix")
        (mkExt "pinage404" "bash-extension-pack")
        ## -- Programming languages/lsp support -- ##
        ## -- git -- ##
        pkgs.vscode-extensions.github.vscode-pull-request-github
        (mkExt "github" "vscode-github-actions")
        ## -- Misc Utils -- ##
        (mkExt "esbenp" "prettier-vscode")
        (mkExt "davidanson" "vscode-markdownlint")
        (mkExt "njpwerner" "autodocstring")
        (mkExt "mikestead" "dotenv")
        (mkExt "humao" "rest-client")
        ## -- Misc Utils -- ##

        ## -- Nix Utils -- ##
        (mkExt "jnoortheen" "nix-ide")
        (mkExt "mkhl" "direnv")
        (mkExt "rubymaniac" "vscode-direnv")
        (mkExt "brettm12345" "nixfmt-vscode")
        ## -- Nix Utils -- ##

        ## -- Java Utils -- ##
        (mkExt "redhat" "java")
        (mkExt "vscjava" "vscode-gradle")
        (mkExt "vscjava" "vscode-java-debug")
        (mkExt "vscjava" "vscode-java-pack")
        ## -- Java Utils -- ##

        ## -- C/C++ Utils -- ##
        (mkExt "ms-vscode" "cpptools-extension-pack")
        (mkExt "formulahendry" "code-runner")
        (mkExt "danielpinto8zz6" "c-cpp-compile-run")
        (mkExt "ms-vscode" "makefile-tools")
        (mkExt "cschlosser" "doxdocgen")
        ## -- C/C++ Utils -- ##

        ## -- Dotnet Utils -- ##
        (mkExt "ms-dotnettools" "vscode-dotnet-pack")
        ## -- Dotnet Utils -- ##

        ## -- Python Utils -- ##
        # Fuck you sarco
        (mkExt "batisteo" "vscode-django")
        (mkExt "donjayamanne" "python-environment-manager")
        (mkExt "kaih2o" "python-resource-monitor")
        (mkExt "kevinrose" "vsc-python-indent")
        (mkExt "ms-python" "black-formatter")
        (mkExt "ms-python" "flake8")
        (mkExt "ms-python" "gather")
        (mkExt "ms-python" "isort")
        (mkExt "ms-python" "debugpy")
        (mkExt "ms-python" "mypy-type-checker")
        (mkExt "ms-python" "pylint")
        (mkExt "wholroyd" "jinja")
        vscode-marketplace.ms-python.python
        vscode-marketplace.ms-toolsai.jupyter
        ## -- Python Utils -- ##

        ## -- JavaScript/Typescript Utils -- ##
        (mkExt "angular" "ng-template")
        (mkExt "bradlc" "vscode-tailwindcss")
        (mkExt "christian-kohler" "npm-intellisense")
        (mkExt "dbaeumer" "vscode-eslint")
        (mkExt "dsznajder" "es7-react-js-snippets")
        (mkExt "ecmel" "vscode-html-css")
        (mkExt "firefox-devtools" "vscode-firefox-debug")
        (mkExt "formulahendry" "auto-close-tag")
        (mkExt "formulahendry" "auto-rename-tag")
        (mkExt "hollowtree" "vue-snippets")
        (mkExt "jasonnutter" "search-node-modules")
        (mkExt "johnpapa" "angular2")
        (mkExt "msjsdiag" "vscode-react-native")
        (mkExt "octref" "vetur")
        (mkExt "prisma" "prisma")
        (mkExt "ritwickdey" "liveserver")
        (mkExt "steoates" "autoimport")
        (mkExt "vue" "volar")
        (mkExt "wix" "vscode-import-cost")
        ## -- JavaScript/Typescript Utils -- ##

        ## -- Vscode specific -- ##
        (mkExt "aaron-bond" "better-comments")
        (mkExt "christian-kohler" "path-intellisense")
        (mkExt "donjayamanne" "githistory")
        (mkExt "donjayamanne" "git-extension-pack")
        (mkExt "eamodio" "gitlens")
        (mkExt "ms-vscode" "hexeditor")
        (mkExt "ms-vsliveshare" "vsliveshare")
        (mkExt "streetsidesoftware" "code-spell-checker")
        (mkExt "visualstudioexptteam" "intellicode-api-usage-examples")
        (mkExt "visualstudioexptteam" "vscodeintellicode")
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
  home.packages = [ pkgs.nil ];
}
