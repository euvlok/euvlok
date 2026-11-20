{ lib, pkgs, ... }:
{
  packages = lib.attrsets.attrValues { inherit (pkgs.unstable) zig zls; };
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
  zed.lsp.zls.binary.path = lib.meta.getExe pkgs.unstable.zls;
}
