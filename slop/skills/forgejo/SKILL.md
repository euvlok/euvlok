---
name: forgejo
description: Forgejo and Codeberg repository operations through the configured Forgejo MCP server, including issues, pull requests, reviews, and CI. Applies to remote Forgejo work, not GitLab or local-only Git operations.
---

# Forgejo

Prefer the configured `forgejo` MCP server for remote Forgejo operations. Confirm
the target instance and available tools before making requests.

## Before working

- Identify the instance, owner, and repository from the repository's remote URL
  or the user's Forgejo link.
- Treat Tenjin (`https://git.tenjin-dk.com`) as the configured instance, not the
  destination for every Forgejo request. Codeberg and other instances need their
  own server configuration.
- Discover the server's available tools and inspect their schemas before calling
  them. Supported operations depend on the installed MCP server and Forgejo
  versions.

## Choosing tools

- Use local JJ in JJ workspaces, or Git otherwise, for diffs, history, and
  working-tree operations.
- Do not use `glab` or the GitLab MCP server for Forgejo operations.
- If the Forgejo MCP server lacks an operation, consult the target instance's
  `/api/swagger` or `/swagger.v1.json` before using its API. Do not assume GitHub
  or GitLab API compatibility.
- Follow pagination when a complete listing is required.

## Authentication

- Let the launcher load authentication from the SOPS template `forjego_tenjin`.
  The template is rendered from the same-named secret containing `FORGEJO_URL`
  and `FORGEJO_ACCESS_TOKEN`.
- Set `FORGEJO_URL` to a complete HTTP(S) URL.
- Preserve the identifier `forjego_tenjin`. Its spelling is intentional in the
  existing configuration; do not rename it as a typo correction.
- Do not read or print the secret to troubleshoot authentication.

## Checking connectivity

- Verify MCP initialization and tool discovery, then call an available read-only
  tool to retrieve the authenticated user or a known repository. Initialization
  alone does not prove API connectivity or token access.
- If no Forgejo tools are exposed, inspect the configured launcher and its startup
  error before investigating token permissions.
- Use startup errors to diagnose invalid URLs, DNS failures, and TLS failures
  before checking token permissions.
- For a missing secret, provision it through SOPS and activate the relevant
  Home Manager configuration.
- For an authorization failure, check token scopes and repository access.

### macOS DNS

- Keep `GODEBUG=netdns=go` in the shared server configuration. The native resolver
  can stall during the API connection check, before MCP initialization.
- For a startup timeout, confirm that the client passes this setting to the
  launcher. Increasing the timeout does not fix a failing DNS lookup.
- Use `GODEBUG=netdns=2` to report which resolver Go selected without enabling
  HTTP debug logging.

## Maintaining configuration

- Edit the source in `/etc/nixos/slop/skills/forgejo`. The installed skill is a
  Home Manager symlink; do not edit files inside `/nix/store`.
- After changing the launcher, shared server settings, or skill source, activate
  the relevant Home Manager configuration and reconnect the MCP client.
- When applying a tested fix directly to live client settings, update the Nix
  configuration too so activation preserves the change.

## References

- [Forgejo MCP](https://git.b4mad.industries/agentic-forges/forgejo-mcp)
- [Forgejo API usage](https://forgejo.org/docs/latest/user/api/usage/)
