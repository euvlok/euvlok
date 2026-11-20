{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      swiftpm
      swift-format
      sourcekit-lsp
      ;
    # The Darwin toolchain also ships clang. Prefer the standalone C++ wrapper.
    swift =
      if pkgs.stdenv.hostPlatform.isDarwin then
        lib.meta.setPrio (pkgs.unstable.llvmPackages_latest.clang.meta.priority + 1) pkgs.unstable.swift
      else
        pkgs.unstable.swift;
  };
  vscode.extensions = [
    "swift-server.swift"
    "vknabel.swift-coverage"
  ];
  vscode.settings."[swift]" = {
    "editor.defaultFormatter" = "swift-server.swift";
    "editor.formatOnSave" = true;
  };
  helix.languageServers.sourcekit-lsp.command = "sourcekit-lsp";
  helix.languages = [
    {
      name = "swift";
      auto-format = true;
      language-servers = [ "sourcekit-lsp" ];
    }
  ];
  zed.extensions = [
    "swift"
    "package-swift-lsp"
  ];
  zed.languages."Swift" = {
    language_servers = [ "sourcekit-lsp" ];
    formatter = "language_server";
  };
  zed.lsp.sourcekit-lsp.binary.path = lib.meta.getExe pkgs.unstable.sourcekit-lsp;
}
