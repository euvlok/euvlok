{ pkgs, lib, ... }:
let
  llvmPackages = pkgs.unstable.llvmPackages_latest;
  clangdArguments = [
    # Query only the selected compiler wrappers for SDK and standard-library headers.
    "--query-driver=${llvmPackages.clang}/bin/clang,${llvmPackages.clang}/bin/clang++"
  ];
in
{
  packages = lib.attrsets.attrValues {
    inherit (llvmPackages)
      clang
      clang-tools
      lld
      lldb
      llvm
      ;
    inherit (pkgs.unstable)
      ccls
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
      "editor.defaultFormatter" = "ms-vscode.cpptools";
      "editor.formatOnSave" = true;
      "editor.codeActionsOnSave"."source.fixAll" = "explicit";
    };
    "[c]" = {
      "editor.defaultFormatter" = "ms-vscode.cpptools";
      "editor.formatOnSave" = true;
      "editor.codeActionsOnSave"."source.fixAll" = "explicit";
    };
    "C_Cpp.default.cppStandard" = "c++23";
    "C_Cpp.default.cStandard" = "c23";
    "C_Cpp.default.compilerPath" = lib.meta.getExe' llvmPackages.clang "clang";
    "C_Cpp.clang_format_path" = lib.meta.getExe' llvmPackages.clang-tools "clang-format";
  };
  helix.languageServers.clangd = {
    command = lib.meta.getExe' llvmPackages.clang-tools "clangd";
    args = clangdArguments;
  };
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
      formatter.external.command = lib.meta.getExe' llvmPackages.clang-tools "clang-format";
    };
    "C++" = {
      language_servers = [ "clangd" ];
      code_actions_on_format."source.fixAll" = true;
      formatter.external.command = lib.meta.getExe' llvmPackages.clang-tools "clang-format";
    };
  };
  zed.lsp.clangd.binary = {
    path = lib.meta.getExe' llvmPackages.clang-tools "clangd";
    arguments = clangdArguments ++ [
      "--header-insertion=iwyu"
      "--completion-style=detailed"
      "--fallback-style=llvm"
    ];
  };
}
