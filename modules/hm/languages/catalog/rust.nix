{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable.rustPackages)
      rustc
      cargo
      rustfmt
      clippy
      ;
    inherit (pkgs.unstable.llvmPackages_latest) lldb;
    inherit (pkgs.unstable)
      rust-analyzer
      cargo-watch
      cargo-edit
      cargo-outdated
      crates-lsp
      ;
  };
  helix.languageServers.rust-analyzer.command = "rust-analyzer";
  helix.languages = [
    {
      name = "rust";
      auto-format = true;
      language-servers = [ "rust-analyzer" ];
    }
  ];
  zed.extensions = [
    "cargo-appraiser"
    "crates-lsp"
  ];
  zed.languages."Rust" = {
    language_servers = [ "rust-analyzer" ];
    code_actions_on_format = {
      "source.fixAll" = true;
      "source.organizeImports" = true;
    };
    formatter = "language_server";
  };
  zed.lsp = {
    crates-lsp.binary.path = lib.meta.getExe pkgs.unstable.crates-lsp;
    rust-analyzer = {
      binary.path = lib.meta.getExe pkgs.unstable.rust-analyzer;
      initialization_options = {
        cargo = {
          buildScripts.enable = true;
          features = "all";
        };
        procMacro.enable = true;
        diagnostics.disabled = [ "unresolved-proc-macro" ];
      };
    };
  };
}
