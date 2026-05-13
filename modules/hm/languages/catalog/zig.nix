{ pkgs, ... }:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) zig zls; };
  vscode.extensions = [ "ziglang.vscode-zig" ];
  vscode.settings = {
    "[zig]" = {
      editor.defaultFormatter = "ziglang.vscode-zig";
      editor.formatOnSave = true;
      editor.codeActionsOnSave.source.fixAll = "explicit";
    };
    "zig.path" = "zig";
    "zig.zls.path" = "zls";
    "zig.initialSetupDone" = true;
  };
  helix.languageServers.zls.command = "zls";
  helix.languages = [
    {
      name = "zig";
      auto-format = true;
      language-servers = [ "zls" ];
    }
  ];
  zed.extensions = [
    "zig"
    "ziggy"
  ];
  zed.languages."Zig" = {
    language_servers = [ "zls" ];
    code_actions_on_format."source.fixAll" = true;
    formatter = "language_server";
  };
  zed.lsp.zls.binary.path = "zls";
}
