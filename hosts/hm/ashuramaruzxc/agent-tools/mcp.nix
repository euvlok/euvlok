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
  /**
    Check whether the current host declares a SOPS secret

    # Inputs

    `name`
    : Key in `sops.secrets`, not the path to the secret on disk

    # Type
    ```
    hasSecret :: String -> Bool
    ```

    # Examples
    :::{.example}
    ## `hasSecret` usage example
    On a host without the SOPS module:
    ```nix
    hasSecret "context7_api_key"
    => false
    ```
    :::
  */
  hasSecret = name: secrets ? ${name};
  context7 =
    if hasSecret secretNames.context7 then
      pkgs.writeShellApplication {
        name = "context7-mcp";
        meta.mainProgram = "context7-mcp";
        text = ''
          CONTEXT7_API_KEY=$(< ${lib.strings.escapeShellArg secrets.${secretNames.context7}.path})
          export CONTEXT7_API_KEY
          exec ${lib.meta.getExe packages.context7-mcp} "$@"
        '';
      }
    else
      packages.context7-mcp;
  /**
    Wrap an MCP server to export the environment from a runtime SOPS template

    Return the original package if the host does not declare the secret

    # Inputs

    `options`
    : Required fields: `name` names the wrapper executable, `package` is a
      derivation with a `meta.mainProgram`, `secret` names the secret and
      its matching template, and `setup` is Bash to run after sourcing it

    # Type
    ```
    withEnvironment :: { name :: String; package :: Derivation; secret :: String; setup :: String; } -> Derivation
    ```

    # Examples
    :::{.example}
    ## `withEnvironment` usage example
    On a host without the GitLab secret:
    ```nix
    withEnvironment {
      name = "gitlab-mcp";
      package = packages.glab;
      secret = secretNames.gitlab;
      setup = "";
    }
    => packages.glab
    ```
    :::
  */
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
        meta.mainProgram = name;
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
    context7.command = lib.meta.getExe context7;
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
  /**
    Strip Codex-only settings before exporting a server to other clients

    # Inputs

    `server`
    : Server settings, optionally including a `codex` attribute

    # Type
    ```
    generic :: AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `generic` usage example
    ```nix
    generic { command = "mcp-nixos"; codex.tool_timeout_sec = 120; }
    => { command = "mcp-nixos"; }
    ```
    :::
  */
  generic = server: lib.attrsets.removeAttrs server [ "codex" ];
  ompServers = lib.attrsets.mapAttrs (_: server: lib.hm.mcp.addType (generic server)) servers;
  /**
    Add overridable Codex defaults to the shared MCP server settings

    # Inputs

    `server`
    : Shared server settings, optionally including a `codex` attribute set.
      Shared keys win over the corresponding Codex defaults

    # Type
    ```
    codexServer :: AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `codexServer` usage example
    ```nix
    (codexServer { command = "mcp-nixos"; codex.tool_timeout_sec = 120; }).tool_timeout_sec
    => lib.modules.mkDefault 120
    ```
    :::
  */
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
          enable = lib.modules.mkIf (
            config.programs.zed-editor.enable || config.programs.claude-code.enable
          ) true;
          servers = lib.attrsets.mapAttrs (_: generic) servers;
        };
        programs.claude-code.enableMcpIntegration = true;
      }
      (lib.modules.mkIf config.programs.codex.enable {
        programs.codex.settings.mcp_servers = lib.attrsets.mapAttrs (_: codexServer) servers;
      })
    ]
    ++ lib.lists.optional (options ? sops.templates) {
      sops.templates =
        lib.attrsets.genAttrs
          (lib.lists.filter hasSecret [
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
