{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable)
      lua
      luarocks
      lua-language-server
      stylua
      ;
  };
  vscode.extensions = [
    "keyring.lua"
    "sumneko.lua"
  ];
  vscode.settings."[lua]" = {
    editor.defaultFormatter = "sumneko.lua";
    editor.formatOnSave = true;
  };
  helix.languageServers.lua-language-server.command = "lua-language-server";
  helix.languages = [
    {
      name = "lua";
      auto-format = true;
      language-servers = [ "lua-language-server" ];
    }
  ];
  zed.extensions = [
    "lua"
    "luau"
  ];
  zed.languages."Lua" = {
    language_servers = [ "lua-language-server" ];
    formatter.external = {
      command = "stylua";
      arguments = [
        "--stdin-filepath"
        "{buffer_path}"
        "-"
      ];
    };
  };
  zed.lsp.lua-language-server = {
    binary.path = "lua-language-server";
    initialization_options.Lua = {
      telemetry.enable = false;
      workspace.checkThirdParty = false;
    };
  };
}
