{ pkgs, ... }:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable) php intelephense;
    inherit (pkgs.unstable.phpPackages) composer psalm phpstan;
  };
  vscode.extensions = [
    "devsense.phptools-vscode"
    "bmewburn.vscode-intelephense-client"
    "xdebug.php-debug"
  ];
  vscode.settings."[php]" = {
    editor.defaultFormatter = "bmewburn.vscode-intelephense-client";
    editor.formatOnSave = true;
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
    path = "intelephense";
    arguments = [ "--stdio" ];
  };
}
