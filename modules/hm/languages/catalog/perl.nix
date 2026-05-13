{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable) perl;
    inherit (pkgs.unstable.perlPackages) PerlLanguageServer PerlCritic PerlTidy;
  };
  vscode.extensions = [ "richterger.perl" ];
  vscode.settings."[perl]" = {
    editor.defaultFormatter = "richterger.perl";
    editor.formatOnSave = true;
  };
  helix.languageServers.perlnavigator = {
    command = "perlnavigator";
    args = [ "--stdio" ];
  };
  helix.languages = [
    {
      name = "perl";
      auto-format = true;
      language-servers = [ "perlnavigator" ];
    }
  ];
  zed.extensions = [ "perl" ];
  zed.languages."Perl".language_servers = [ "perlnavigator" ];
  zed.lsp.perlnavigator.binary.path = "perlnavigator";
}
