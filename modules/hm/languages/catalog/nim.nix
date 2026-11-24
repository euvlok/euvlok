{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues { inherit (pkgs.unstable) nim nimlsp; };
  mitos.languageServers.nimlsp.command = "nimlsp";
  mitos.languages = [
    {
      name = "nim";
      auto-format = true;
      language-servers = [ "nimlsp" ];
    }
  ];
  zed.extensions = [ "nim" ];
  zed.languages."Nim".language_servers = [ "nim" ];
  zed.lsp.nim.binary.path = lib.meta.getExe pkgs.unstable.nimlsp;
}
