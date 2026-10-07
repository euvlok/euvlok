{ pkgs, lib, ... }:
let
  ruffSettings = {
    configurationPreference = "filesystemFirst";
    configuration = {
      "line-length" = 80;
      lint."extend-select" = [ "I" ];
    };
  };
  tySettings.diagnosticMode = "workspace";
in
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable) uv ty ruff;
    python = pkgs.python313.withPackages (pythonPackages: [
      pythonPackages.ipython
      pythonPackages.jupyter
    ]);
  };
  vscode.extensions = [
    "astral-sh.ty"
    "charliermarsh.ruff"
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-python-envs"
    "ms-toolsai.jupyter"
  ];
  vscode.settings = {
    "python.languageServer" = "None";
    "python.useEnvironmentsExtension" = true;
    "python-envs.alwaysUseUv" = true;
    "ty.path" = [ (lib.meta.getExe pkgs.unstable.ty) ];
    "ty.diagnosticMode" = tySettings.diagnosticMode;
    "ruff.path" = [ (lib.meta.getExe pkgs.unstable.ruff) ];
    "ruff.nativeServer" = "on";
    "ruff.configurationPreference" = ruffSettings.configurationPreference;
    "ruff.configuration" = ruffSettings.configuration;
    "[python]" = {
      "editor.defaultFormatter" = "charliermarsh.ruff";
      "editor.codeActionsOnSave" = {
        "source.fixAll.ruff" = "explicit";
        "source.organizeImports.ruff" = "explicit";
      };
      "editor.formatOnSave" = true;
      "editor.insertSpaces" = true;
    };
  };
  helix.languageServers = {
    ruff = {
      command = lib.meta.getExe pkgs.unstable.ruff;
      args = [ "server" ];
      config.settings = ruffSettings;
    };
    ty = {
      command = lib.meta.getExe pkgs.unstable.ty;
      args = [ "server" ];
      config.ty = tySettings;
    };
  };
  helix.languages = [
    {
      name = "python";
      auto-format = true;
      language-servers = [
        "ty"
        {
          name = "ruff";
          only-features = [
            "diagnostics"
            "code-action"
            "format"
          ];
        }
      ];
    }
  ];
  zed.extensions = [
    "python-snippets"
    "python-requirements"
    "python-refactoring"
    "django-snippets"
    "flask-snippets"
  ];
  zed.languages."Python" = {
    language_servers = [
      "ty"
      "ruff"
    ];
    code_actions_on_format = {
      "source.fixAll.ruff" = true;
      "source.organizeImports.ruff" = true;
    };
    formatter.language_server.name = "ruff";
  };
  zed.lsp = {
    ty = {
      binary = {
        path = lib.meta.getExe pkgs.unstable.ty;
        arguments = [ "server" ];
      };
      settings = tySettings;
    };
    ruff = {
      binary = {
        path = lib.meta.getExe pkgs.unstable.ruff;
        arguments = [ "server" ];
      };
      initialization_options.settings = ruffSettings;
    };
  };
}
