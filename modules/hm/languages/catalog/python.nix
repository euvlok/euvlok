{ pkgs, ... }:
let
  python313 = pkgs.python313.withPackages (pip: [
    pip.black
    pip.flake8
    pip.ipython
    pip.isort
    pip.jupyter
    pip.mypy
    pip.pylint
    pip.ruff
    pip.jedi
    pip.python-lsp-server
  ]);
in
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable) basedpyright;
    python = python313;
  };
  vscode.extensions = [
    "charliermarsh.ruff"
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-toolsai.jupyter"
  ];
  vscode.settings = {
    "ruff.nativeServer" = "on";
    "[python]" = {
      editor.defaultFormatter = "charliermarsh.ruff";
      editor.codeActionsOnSave = {
        source.fixAll.ruff = "explicit";
        source.organizeImports.ruff = "explicit";
      };
      editor.formatOnSave = true;
    };
  };
  helix.languageServers = {
    ruff = {
      command = "ruff";
      args = [
        "server"
        "--preview"
      ];
      config.lineLength = 100;
      config.lint.extendSelect = [ "I" ];
    };
    pylsp = {
      command = "pylsp";
      plugins.pylsp_mypy.enable = true;
      plugins.pylsp_mypy.live_mode = true;
    };
    jedi.command = "jedi-language-server";
  };
  helix.languages = [
    {
      name = "python";
      auto-format = true;
      language-servers = [
        "ruff"
        "pylsp"
        "jedi"
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
      "basedpyright"
      "ruff"
    ];
    code_actions_on_format = {
      "source.fixAll.ruff" = true;
      "source.organizeImports.ruff" = true;
    };
    formatter.language_server.name = "ruff";
  };
  zed.lsp = {
    basedpyright = {
      binary = {
        path = "basedpyright-langserver";
        arguments = [ "--stdio" ];
      };
      settings."basedpyright.analysis".typeCheckingMode = "strict";
    };
    ruff.binary = {
      path = "ruff";
      arguments = [
        "server"
        "--preview"
      ];
    };
  };
}
