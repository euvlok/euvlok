{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  release,
  ...
}:
let
  mkExt = (pkgs.callPackage ./lib.nix { inherit inputs osConfig; }).mkExt;

  extensions =
    [
      # Nix
      (mkExt "bbenoist" "nix")
      (mkExt "jnoortheen" "nix-ide")
      (mkExt "kamadorueda" "alejandra")

      # Shells
      (mkExt "bmalehorn" "shell-syntax")
      (mkExt "mads-hartmann" "bash-ide-vscode")
      (mkExt "timonwong" "shellcheck")

      # Languages
      (mkExt "charliermarsh" "ruff")
      (mkExt "davidanson" "vscode-markdownlint")
      (mkExt "dbaeumer" "vscode-eslint")
      (mkExt "mgmcdermott" "vscode-language-babel")
      (mkExt "tamasfe" "even-better-toml")
      (mkExt "yzhang" "markdown-all-in-one")

      # Misc
      (mkExt "editorconfig" "editorconfig")
      (mkExt "oderwat" "indent-rainbow")
      (mkExt "visualstudioexptteam" "vscodeintellicode")
    ]
    ++ lib.optionals config.profiles.direnv.enable [ (mkExt "mkhl" "direnv") ]
    ++ lib.optionals config.profiles.fish.enable [ (mkExt "bmalehorn" "vscode-fish") ]
    ++ lib.optionals config.programs.nushell.enable [
      (mkExt "thenuprojectcontributors" "vscode-nushell-lang")
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
    "[python]" = {
      editor.defaultFormatter = "charliermarsh.ruff";
      editor.codeActionsOnSave = {
        source.fixAll.ruff = "explicit";
        source.organizeImports.ruff = "explicit";
      };
      editor.formatOnSave = true;
    };
    "[html]" = {
      editor.defaultFormatter = "esbenp.prettier-vscode";
    };
    "[yaml]" = {
      editor.defaultFormatter = "esbenp.prettier-vscode";
      editor.formatOnSave = true;
    };
    "[yml]" = {
      editor.defaultFormatter = "esbenp.prettier-vscode";
      editor.formatOnSave = true;
    };
    "[toml]" = {
      editor.defaultFormatter = "tamasfe.even-better-toml";
      editor.formatOnSave = true;
    };

    bashIde.explainshellEndpoint = "http://
    localhost:5134";
  };
in
{
  options.hm.vscode.enable = lib.mkEnableOption "VSCode";

  config = lib.mkIf config.hm.vscode.enable {
    programs.vscode =
      {
        enable = true;
        package = lib.mkIf (osConfig.nixpkgs.hostPlatform.isLinux) (
          pkgs.vscode.override {
            commandLineArgs = "--wayland-text-input-version=3 --enable-wayland-ime";
          }
        );
      }
      // lib.optionalAttrs (release < 25) {
        inherit extensions;
        userSettings = settings;
      }
      // lib.optionalAttrs (release > 25) {
        profiles.default.extensions = extensions;
        profiles.default.userSettings = settings;
      };
  };
}
