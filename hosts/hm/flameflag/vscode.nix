{
  pkgs,
  lib,
  config,
  eulib,
  ...
}:
let
  inherit (config.programs.vscode.package) version;
  mkExt = eulib.mkExt version;

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

  utils = {
    extensions = builtins.attrValues { inherit (pkgs.vscode-extensions.github) copilot copilot-chat; };
    settings = {
      github.copilot.enable = {
        "*" = false;
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
        utils
      ];
      excludePaths = [
        "[javascript]"
        "[nix]"
        "[typescript]"
        "github.copilot.enable"
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
  programs.vscode.profiles.default.extensions = mergeFrom "extensions";

  programs.vscode.profiles.default.userSettings = {
    "editor.fontFamily" = "'MonaspiceKr Nerd Font Mono', 'UbuntuMono Nerd Font', monospace";
    "editor.wordWrap" = "on";
    "editor.mouseWheelZoom" = true;
    "editor.guides.bracketPairs" = "active";
    "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
    "editor.accessibilitySupport" = "off";

    "workbench.editor.showIcons" = true;
    "workbench.colorTheme" = lib.mkForce "Catppuccin Frappé";
    "window.zoomLevel" = 1.5;
    "terminal.integrated.fontFamily" =
      "'MonaspiceKr Nerd Font Mono', 'UbuntuMono Nerd Font', monospace";

    "diffEditor.ignoreTrimWhitespace" = false;

    "security.workspace.trust.enabled" = false;

    # Catppuccin
    ## Make semantic highlighting look good
    "editor.semanticHighlighting.enabled" = true;
    ## Prevent VSCode from modifying the terminal colors
    "terminal.integrated.minimumContrastRatio" = 1;
    ## Make the window's titlebar use the workbench colors
    "window.titleBarStyle" = "custom";

    # MCP servers
    mcp = {
      servers = {
        context7 = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "@upstash/context7-mcp"
          ];
        };
      };
    };
  }
  // mergeFrom "settings";
}
