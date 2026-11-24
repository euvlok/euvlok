{ pkgs, lib, ... }:
let
  llvmPackages = pkgs.unstable.llvmPackages_latest;
  clangdArguments = [
    # Query only the selected compiler wrappers for SDK and standard-library headers.
    "--query-driver=${lib.meta.getExe' llvmPackages.clang "clang"},${lib.meta.getExe' llvmPackages.clang "clang++"}"
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
  mitos.languageServers.clangd = {
    command = lib.meta.getExe' llvmPackages.clang-tools "clangd";
    args = clangdArguments;
  };
  mitos.languages = [
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
