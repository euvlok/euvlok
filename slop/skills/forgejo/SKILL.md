---
name: forgejo
description: Work with Forgejo repositories, issues, pull requests, reviews, and CI through the configured Forgejo MCP server. Use for Forgejo or Codeberg tasks, not GitLab or local-only Git operations.
---

# Forgejo

Prefer the configured `forgejo` MCP server for remote Forgejo operations.
Discover its available tools and inspect their schemas before calling them;
the installed server and Forgejo versions determine which operations exist.

The personal configuration targets Tenjin. Check the repository's remote URL
or the user's Forgejo link before selecting an instance, owner, and repository.
Codeberg and other Forgejo instances need their own server configuration; do not
send their requests to Tenjin.

Authentication is loaded by the launcher from the SOPS template `forjego_tenjin`,
rendered from the same-named secret containing `FORGEJO_URL` and
`FORGEJO_ACCESS_TOKEN`. `FORGEJO_URL` must be a full HTTP(S) URL. Tenjin's public
URL is `https://git.tenjin-dk.com`. The `forjego_tenjin` spelling is the existing
secret identifier. Do not rename it as a typo correction.
Do not read or print the secret to troubleshoot authentication. Use the launcher's
startup error to diagnose invalid URLs, DNS, and TLS failures before checking
token permissions. A missing secret requires SOPS provisioning and Home Manager
activation; an authorization failure may require different token scopes or
repository access.

For a health check, verify MCP initialization and tool discovery, then use an
available read-only tool to retrieve the authenticated user or a known
repository. Initialization alone does not prove API connectivity or token access.
If no Forgejo tools are exposed, check the configured launcher and its startup
error before diagnosing token permissions. After changing the launcher or skill
source in `/etc/nixos`, rebuild and activate the relevant Home Manager
configuration, then reconnect the MCP client to load the changes.

Use local JJ in JJ workspaces, or Git otherwise, for diffs, history, and
working-tree operations. The `glab` CLI
and GitLab MCP server do not operate on Forgejo. If the Forgejo MCP server lacks
an operation, consult the target instance's `/api/swagger` or
`/swagger.v1.json` before using its API. Follow pagination for complete listings;
do not assume GitHub or GitLab API compatibility.

References:

- [Forgejo MCP](https://git.b4mad.industries/agentic-forges/forgejo-mcp)
- [Forgejo API usage](https://forgejo.org/docs/latest/user/api/usage/)
