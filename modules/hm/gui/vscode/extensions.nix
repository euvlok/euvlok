{
  lib,
  config,
  eulib,
  ...
}:
let
  inherit (config.programs.vscode.package) version;
  mkExt = eulib.mkExt version;

  extensions = [
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
  ];

  settings = {
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
  };
in
{
  config = lib.mkIf config.hm.vscode.enable {
    programs.vscode.profiles.default.extensions = extensions;
    programs.vscode.profiles.default.userSettings = settings;
  };
}
