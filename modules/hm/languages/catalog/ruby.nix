{ pkgs, lib, ... }:
{
  packages = lib.attrsets.attrValues {
    inherit (pkgs.unstable) ruby_4_0 solargraph rubocop;
    inherit (pkgs.unstable.rubyPackages)
      rails
      ruby-lsp
      ;
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
