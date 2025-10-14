{ lib, ... }:
let
  language-server = {
    bash-language-server = {
      args = [ "start" ];
      command = "bash-language-server";
      config.enable = true;
    };
    nil = {
      command = "nil";
      config.nil.formatting.command = [ "nixfmt" ];
    };
    yaml-language-server = {
      command = "yaml-language-server";
      args = [ "--stdio" ];
      config = {
        yaml = {
          format.enable = true;
          validation = true;
          schemas.https = true;
        };
      };
    };
    taplo = {
      command = "taplo";
      args = lib.splitString " " "lsp stdio";
      config.formatter.alignEntries = true;
      config.formatter.columnWidth = 100;
    };
  };

  language = [
    {
      name = "nix";
      auto-format = true;
      language-servers = [ "nil" ];
    }
    {
      name = "bash";
      auto-format = true;
      diagnostic-severity = "warning";
      formatter.args = [ "-w" ];
      formatter.command = "shfmt";
      language-servers = [ "bash-language-server" ];
    }
    {
      name = "yaml";
      auto-format = true;
      language-servers = [ "yaml-language-server" ];
    }
    {
      name = "toml";
      auto-format = true;
      language-servers = [ "taplo" ];
    }
  ];
in
{
  programs.helix.languages = { inherit language-server language; };
}
