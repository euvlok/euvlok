{ pkgs, ... }:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable)
      ccls
      clang
      clang-tools
      cmake
      gdb
      gnumake
      ninja
      pkg-config
      # valgrind #!tbh quite useless
      ;
  };
  vscode.extensions = [
    "ms-vscode.cmake-tools"
    "ms-vscode.cpptools"
    "ms-vscode.cpptools-extension-pack"
    "twxs.cmake"
  ];
  vscode.settings = {
    "[cpp]" = {
      editor.defaultFormatter = "ms-vscode.cpptools";
      editor.formatOnSave = true;
      editor.codeActionsOnSave.source.fixAll = "explicit";
    };
    "[c]" = {
      editor.defaultFormatter = "ms-vscode.cpptools";
      editor.formatOnSave = true;
      editor.codeActionsOnSave.source.fixAll = "explicit";
    };
    "C_Cpp.default.cppStandard" = "c++23";
    "C_Cpp.default.cStandard" = "c23";
    "C_Cpp.default.intelliSenseMode" = "linux-gcc-x64";
  };
  helix.languageServers.clangd.command = "clangd";
  helix.languages = [
    {
      name = "c";
      auto-format = true;
      language-servers = [ "clangd" ];
    }
    {
      name = "cpp";
      auto-format = true;
      language-servers = [ "clangd" ];
    }
  ];
  zed.languages = {
    "C" = {
      language_servers = [ "clangd" ];
      code_actions_on_format."source.fixAll" = true;
      formatter.external.command = "clang-format";
    };
    "C++" = {
      language_servers = [ "clangd" ];
      code_actions_on_format."source.fixAll" = true;
      formatter.external.command = "clang-format";
    };
  };
  zed.lsp.clangd.binary = {
    path = "clangd";
    arguments = [
      "--header-insertion=iwyu"
      "--completion-style=detailed"
      "--fallback-style=llvm"
    ];
  };
}
