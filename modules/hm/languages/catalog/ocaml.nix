{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable) ocaml dune_3 opam;
    inherit (pkgs.unstable.ocamlPackages) ocaml-lsp ocamlformat;
  };
  vscode.extensions = [ "ocamllabs.vscode-ocaml-platform" ];
  vscode.settings."[ocaml]" = {
    editor.defaultFormatter = "ocamllabs.vscode-ocaml-platform";
    editor.formatOnSave = true;
  };
  helix.languageServers.ocamllsp.command = "ocamllsp";
  helix.languages = [
    {
      name = "ocaml";
      auto-format = true;
      language-servers = [ "ocamllsp" ];
    }
  ];
  zed.extensions = [ "ocaml" ];
  zed.languages."OCaml" = {
    language_servers = [ "ocamllsp" ];
    formatter.external = {
      command = "ocamlformat";
      arguments = [
        "--name"
        "{buffer_path}"
        "-"
      ];
    };
  };
  zed.lsp.ocamllsp.binary.path = "ocamllsp";
}
