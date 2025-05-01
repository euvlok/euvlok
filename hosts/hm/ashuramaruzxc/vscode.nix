{
  inputs,
  osConfig,
  config,
  pkgs,
  ...
}:
let
  mkExt = (import ../../../modules/hm/gui/vscode/lib.nix { inherit inputs osConfig pkgs; }).mkExt;
in
{
  programs.vscode = {
    profiles.default = {
      userSettings = {
        "search.followSymlinks" = false;
        "typescript.suggest.paths" = false;
        "javascript.suggest.paths" = false;
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
        "terminal.integrated.minimumContrastRatio" = 1;
        "terminal.integrated.fontFamily" = "'Hack Nerd Font'";
        "terminal.integrated.cursorStyle" = "line";
        "terminal.integrated.cursorBlinking" = true;

        "workbench.editor.showIcons" = true;
        "workbench.iconTheme" = "catppuccin-${config.catppuccin.flavor}";
        "workbench.sideBar.location" = "right";
        "window.titleBarStyle" = "native";
        "telemetry.telemetryLevel" = "off";
        "editor.unicodeHighlight.allowedLocales" = {
          "ja" = true;
          "　" = true;
        };

        # Python
        "[python]" = {
          "formatting.provider" = "none";
          "editor.defaultFormatter" = "omnilib.ufmt";
          "editor.formatOnSave" = true;
        };
      };
      extensions = [
        (mkExt "ms-vscode" "hexeditor")
        (mkExt "ms-vsliveshare" "vsliveshare")
        (mkExt "visualstudioexptteam" "vscodeintellicode")
        (mkExt "visualstudioexptteam" "intellicode-api-usage-examples")
        (mkExt "christian-kohler" "path-intellisense")
        # (mkExt "github" "vscode-pull-request-github")
        pkgs.vscode-extensions.github.vscode-pull-request-github
        (mkExt "donjayamanne" "githistory")
        (mkExt "eamodio" "gitlens")
        (mkExt "aaron-bond" "better-comments")
        (mkExt "streetsidesoftware" "code-spell-checker")
        ## -- Vscode specific -- ##

        ## -- Programming languages/lsp support -- ##
        (mkExt "josetr" "cmake-language-support-vscode")
        (mkExt "ms-python" "python")
        (mkExt "ms-vscode" "cpptools-extension-pack")
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
        (mkExt "github" "vscode-github-actions")
        (mkExt "mathematic" "vscode-latex")
        # (mkExt "lizebang" "bash-extension-pack")

        ## -- Programming languages/lsp support -- ##

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
        (mkExt "omnilib" "ufmt")
        (mkExt "ms-python" "black-formatter")
        (mkExt "ms-python" "pylint")
        (mkExt "ms-python" "debugpy")
        (mkExt "batisteo" "vscode-django")
        (mkExt "kevinrose" "vsc-python-indent")
        (mkExt "wholroyd" "jinja")
        (mkExt "donjayamanne" "python-environment-manager")
        ## -- Python Utils -- ##

        ## -- JavaScript/Typescript Utils -- ##
        (mkExt "steoates" "autoimport")
        (mkExt "ecmel" "vscode-html-css")
        (mkExt "bradlc" "vscode-tailwindcss")
        (mkExt "formulahendry" "auto-rename-tag")
        (mkExt "formulahendry" "auto-close-tag")
        (mkExt "ritwickdey" "liveserver")
        (mkExt "firefox-devtools" "vscode-firefox-debug")
        (mkExt "angular" "ng-template")
        (mkExt "johnpapa" "angular2")
        (mkExt "dbaeumer" "vscode-eslint")
        (mkExt "jasonnutter" "search-node-modules")
        (mkExt "christian-kohler" "npm-intellisense")
        (mkExt "prisma" "prisma")
        (mkExt "wix" "vscode-import-cost")
        (mkExt "octref" "vetur")
        (mkExt "vue" "volar")
        (mkExt "hollowtree" "vue-snippets")
        (mkExt "msjsdiag" "vscode-react-native")
        (mkExt "dsznajder" "es7-react-js-snippets")
        ## -- JavaScript/Typescript Utils -- ##

        ## -- VSCode Themes/Icons -- ##
        (mkExt "catppuccin" "catppuccin-vsc")
        (mkExt "catppuccin" "catppuccin-vsc-icons")
        ## -- VSCode Themes/Icons -- ##

        ## -- Dictionary/Languages support -- ##
        # (mkExt "ms-ceintl" "vscode-language-pack
        pkgs.vscode-extensions.ms-ceintl.vscode-language-pack-ja
        ## -- Dictionary/Languages support -- ##
      ];
    };
  };
  home.sessionVariables = {
    GO_PATH = "${config.home.homeDirectory}/.go";
  };
}
