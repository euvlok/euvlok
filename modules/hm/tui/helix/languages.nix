{ pkgs, lib, ... }:
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
      args = lib.strings.splitString " " "lsp stdio";
      config.formatter.alignEntries = true;
      config.formatter.columnWidth = 100;
    };
    rumdl = {
      command = lib.meta.getExe pkgs.unstable.rumdl;
      args = [ "server" ];
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
    {
      name = "markdown";
      auto-format = true;
      formatter = {
        command = lib.meta.getExe pkgs.unstable.rumdl;
        args = [
          "fmt"
          "--stdin"
          "--stdin-filename"
          "%{buffer_name}"
        ];
      };
      language-servers = [ "rumdl" ];
    }
  ];
in
{
  programs.helix.languages = { inherit language-server language; };
}
