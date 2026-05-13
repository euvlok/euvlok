{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) elixir elixir-ls hex; };
  vscode.extensions = [ "jakebecker.elixir-ls" ];
  vscode.settings."[elixir]" = {
    editor.defaultFormatter = "jakebecker.elixir-ls";
    editor.formatOnSave = true;
  };
  helix.languageServers.elixir-ls.command = "elixir-ls";
  helix.languages = [
    {
      name = "elixir";
      auto-format = true;
      language-servers = [ "elixir-ls" ];
    }
  ];
  zed.extensions = [ "elixir" ];
  zed.languages."Elixir" = {
    language_servers = [ "elixir-ls" ];
    formatter = "language_server";
  };
  zed.lsp.elixir-ls.binary.path = "elixir-ls";
}
