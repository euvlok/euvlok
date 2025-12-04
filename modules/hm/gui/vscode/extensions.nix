{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.hm.vscode.enable {
    programs.vscode.profiles.default = {
      extensions = pkgs.nix4vscode.forVscodeVersion config.programs.vscode.package.version [
        "bbenoist.nix"
        "jnoortheen.nix-ide"
        "kamadorueda.alejandra"
        "bmalehorn.shell-syntax"
        "mads-hartmann.bash-ide-vscode"
        "rogalmic.bash-debug"
        "timonwong.shellcheck"
        "streetsidesoftware.code-spell-checker"
        "usernamehw.errorlens"
        "davidanson.vscode-markdownlint"
        "redhat.vscode-xml"
        "redhat.vscode-yaml"
        "tamasfe.even-better-toml"
        "yzhang.markdown-all-in-one"
        "zainchen.json"
        "dbaeumer.vscode-eslint"
        "mgmcdermott.vscode-language-babel"
        "editorconfig.editorconfig"
        "oderwat.indent-rainbow"
        "visualstudioexptteam.vscodeintellicode"
        "tamasfe.even-better-toml"
      ];
      userSettings = {
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
          "MD033" = false;
          "MD041" = false;
          "MD045" = false;
        };
        bashIde.explainshellEndpoint = "http://localhost:5134";
      };
    };
  };
}
