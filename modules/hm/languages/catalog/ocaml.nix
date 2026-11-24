{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable) ocaml dune_3 opam;
    inherit (pkgs.unstable.ocamlPackages) ocaml-lsp ocamlformat;
  };
  mitos.languageServers.ocamllsp.command = "ocamllsp";
  mitos.languages = [
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
  zed.lsp.ocamllsp.binary.path = lib.meta.getExe' pkgs.unstable.ocamlPackages.ocaml-lsp "ocamllsp";
}
