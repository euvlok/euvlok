{ pkgs, ... }:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable)
      rustc
      rustfmt
      rust-analyzer
      cargo-watch
      cargo-edit
      cargo-outdated
      crates-lsp
      ;
  };
  vscode.extensions = [
    "fill-labs.dependi"
    "rust-lang.rust-analyzer"
  ];
  vscode.settings."[rust]" = {
    editor.defaultFormatter = "rust-lang.rust-analyzer";
    editor.formatOnSave = true;
    editor.codeActionsOnSave = {
      source.fixAll = "explicit";
      source.organizeImports = "explicit";
    };
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
    crates-lsp.binary.path = "crates-lsp";
    rust-analyzer = {
      binary.path = "rust-analyzer";
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
