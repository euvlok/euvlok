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
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable) uv ty ruff;
    python = pkgs.stable.python313.withPackages (pythonPackages: [
      pythonPackages.ipython
      pythonPackages.jupyter
    ]);
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
