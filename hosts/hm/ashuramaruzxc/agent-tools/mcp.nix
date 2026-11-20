{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  packages = pkgs.unstable or pkgs;
  secrets = lib.attrsets.optionalAttrs (options ? sops) config.sops.secrets;
  secretNames = {
    context7 = "context7_api_key";
    forgejo = "forjego_tenjin";
    gitlab = "gitlab_simsoft";
  };
  hasSecret = name: secrets ? ${name};
  context7 =
    if hasSecret secretNames.context7 then
      pkgs.writeShellApplication {
        name = "context7-mcp";
        text = ''
          CONTEXT7_API_KEY=$(< ${lib.escapeShellArg secrets.${secretNames.context7}.path})
          export CONTEXT7_API_KEY
          exec ${lib.getExe packages.context7-mcp} "$@"
        '';
      }
    else
      packages.context7-mcp;
  withEnvironment =
    {
      name,
      package,
      secret,
      setup,
    }:
    if !hasSecret secret then
      package
    else
      pkgs.writeShellApplication {
        inherit name;
        text = ''
          set -a
          # shellcheck source=/dev/null
          source ${lib.strings.escapeShellArg config.sops.templates.${secret}.path}
          set +a
          ${setup}
          exec ${lib.meta.getExe package} "$@"
        '';
      };
  forgejo = withEnvironment {
    name = "forgejo-mcp";
    package = packages.forgejo-mcp;
    secret = secretNames.forgejo;
    setup = ''
      : "''${FORGEJO_ACCESS_TOKEN:?Set FORGEJO_ACCESS_TOKEN}"
      case "''${FORGEJO_URL:-}" in
        https://* | http://*) ;;
        *)
          echo "Set FORGEJO_URL to a full http(s) URL" >&2
          exit 1
          ;;
      esac
    '';
  };
  servers = {
    clickup.url = "https://mcp.clickup.com/mcp";
    cloudflare.url = "https://mcp.cloudflare.com/mcp";
    context7.command = lib.getExe context7;
    gitlab = {
      command = lib.meta.getExe (withEnvironment {
        name = "gitlab-mcp";
        package = packages.glab;
        secret = secretNames.gitlab;
        setup = ''
          : "''${GITLAB_HOST:?Set GITLAB_HOST}"
          : "''${GITLAB_TOKEN:?Set GITLAB_TOKEN}"
        '';
      });
      args = [
        "mcp"
        "serve"
      ];
      codex.env_vars = [
        "GITLAB_HOST"
        "GITLAB_TOKEN"
        "GLAB_CONFIG_DIR"
      ];
      codex.tool_timeout_sec = 120;
    };
    forgejo = {
      command = lib.meta.getExe forgejo;
      args = [
        "--transport"
        "stdio"
      ];
      env = lib.attrsets.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        # The native Go resolver can stall before the MCP handshake on macOS.
        GODEBUG = "netdns=go";
      };
      codex.env_vars = [
        "FORGEJO_URL"
        "FORGEJO_ACCESS_TOKEN"
      ];
      codex.tool_timeout_sec = 120;
    };
    nixos = {
      command = lib.meta.getExe packages.mcp-nixos;
      codex.tool_timeout_sec = 120;
    };
    openaiDeveloperDocs.url = "https://developers.openai.com/mcp";
  };
  generic = server: removeAttrs server [ "codex" ];
  ompServers = lib.mapAttrs (_: server: lib.hm.mcp.addType (generic server)) servers;
  codexServer =
    server:
    lib.attrsets.mapAttrs (_: lib.modules.mkDefault) (
      {
        enabled = true;
        startup_timeout_sec = 20;
        tool_timeout_sec = 60;
        default_tools_approval_mode = "auto";
      }
      // server.codex or { }
    )
    // generic server;
in
{
  config = lib.modules.mkMerge (
    [
      {
        programs.mcp = {
          enable = lib.mkIf (config.programs.zed-editor.enable || config.programs.claude-code.enable) true;
          servers = lib.mapAttrs (_: generic) servers;
        };
        programs.claude-code.enableMcpIntegration = true;
      }
      (lib.modules.mkIf config.programs.codex.enable {
        programs.codex.settings.mcp_servers = lib.attrsets.mapAttrs (_: codexServer) servers;
      })
    ]
    ++ lib.lists.optional (options ? sops.templates) {
      sops.templates =
        lib.genAttrs
          (lib.filter hasSecret [
            secretNames.gitlab
            secretNames.forgejo
          ])
          (secret: {
            content = config.sops.placeholder.${secret};
            mode = "0400";
          });
    }
    ++ lib.lists.optional (options ? euvlok.home.codex.omp.mcpServers) (
      lib.modules.mkIf config.programs.codex.enable {
        euvlok.home.codex.omp.mcpServers = ompServers;
      }
    )
    ++ lib.lists.optional (options ? programs.ai.omp.mcp) (
      lib.modules.mkIf config.programs.ai.omp.enable {
        programs.ai.omp.mcp.mcpServers = ompServers;
      }
    )
  );
}
