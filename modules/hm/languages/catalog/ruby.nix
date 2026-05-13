{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable) ruby_4_0 solargraph rubocop;
    inherit (pkgs.unstable.rubyPackages)
      rails
      ruby-lsp
      ;
  };
  vscode.extensions = [ "shopify.ruby-lsp" ];
  vscode.settings = {
    "rubyLsp.bundleGemfile" = "";
    "rubyLsp.customRubyCommand" = lib.getExe' pkgs.unstable.ruby_4_0 "ruby";
    "rubyLsp.lspPath" = lib.getExe' pkgs.unstable.rubyPackages.ruby-lsp "ruby-lsp";
    "rubyLsp.pullDiagnosticsOn" = "save";
    "rubyLsp.rubyVersionManager" = "none";
    "[ruby]" = {
      editor.defaultFormatter = "shopify.ruby-lsp";
      editor.formatOnSave = true;
    };
  };
  helix.languageServers = {
    ruby-lsp.command = "ruby-lsp";
    solargraph = {
      command = "solargraph";
      args = [ "stdio" ];
    };
  };
  helix.languages = [
    {
      name = "ruby";
      auto-format = true;
      language-servers = [
        "ruby-lsp"
        "solargraph"
      ];
    }
  ];
  zed.extensions = [
    "ruby"
    "thrift"
    "haml"
  ];
  zed.languages."Ruby" = {
    language_servers = [ "ruby-lsp" ];
    formatter = "language_server";
  };
}
