{ pkgs, ... }:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable)
      scala
      sbt
      metals
      scalafmt
      ;
  };
  vscode.extensions = [ "scalameta.metals" ];
  vscode.settings."[scala]" = {
    editor.defaultFormatter = "scalameta.metals";
    editor.formatOnSave = true;
  };
  helix.languageServers.metals.command = "metals";
  helix.languages = [
    {
      name = "scala";
      auto-format = true;
      language-servers = [ "metals" ];
    }
  ];
  zed.extensions = [ "scala" ];
  zed.languages."Scala" = {
    language_servers = [ "metals" ];
    formatter = "language_server";
  };
  zed.lsp.metals.binary.path = "metals";
}
