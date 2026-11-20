{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable) php intelephense phpstan;
    inherit (pkgs.unstable.phpPackages) composer psalm;
  };
  helix.languageServers.intelephense = {
    command = "intelephense";
    args = [ "--stdio" ];
  };
  helix.languages = [
    {
      name = "php";
      auto-format = true;
      language-servers = [ "intelephense" ];
    }
  ];
  zed.extensions = [
    "php"
    "blade"
    "twig"
  ];
  zed.languages."PHP" = {
    language_servers = [ "intelephense" ];
    formatter = "language_server";
    prettier.allowed = false;
  };
  zed.lsp.intelephense.binary = {
    path = lib.meta.getExe pkgs.unstable.intelephense;
    arguments = [ "--stdio" ];
  };
}
