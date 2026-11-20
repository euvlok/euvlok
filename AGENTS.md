# Repository guidance

AI agents may edit this file only with explicit human permission.

## Git and GitHub

- Commit all your work. Use `scope: summary` subjects, e.g. `ci: fix checks`.
- Commit bodies explain only why the change was made. Omit verification notes
  and link relevant issues and PRs.
- Use `redirect.github.com` for GitHub links to avoid backlinks.
- Push directly to `master` only with explicit human approval.
- Prefer `gh` over web search for GitHub repository lookups.

### Opening a bot PR

The [Open PR workflow](.github/workflows/open-pr.yml) must be on both `master`
and the feature branch. Get approval for the push, dispatch, and PR wording.
Push the feature branch, then dispatch from it:

```sh
gh workflow run open-pr.yml -R euvlok/euvlok --ref "$branch" -f title="$title"
```

The workflow opens the PR as `github-actions[bot]` against `master` using the
repository PR template. Add `-f body="$body"` only if the user requests extra
text.

Track the returned run (includes CI). If no URL is returned, find the dispatched
SHA with `gh run list -w open-pr.yml -b "$branch"` instead of dispatching again.
Wait with `gh run watch "$run_id" --exit-status` and inspect failures with
`gh run view "$run_id" --log-failed`.

- Prefer `--json` and `--jq`. For `gh pr checks --json bucket,name,link`, read
  `bucket`, not the exit code. Fetch inline review comments with
  `gh api --paginate "repos/euvlok/euvlok/pulls/$pr/comments"`.
- For PR waits, use `gh event listen` as described in the [official `gh`
  skill][gh-skill]. Get approval before creating a subscription.

[gh-skill]: https://redirect.github.com/cli/cli/blob/HEAD/skills/gh/SKILL.md

## Nix Preferences

### Before writing Nix

- Look for local Nixpkgs sources to consult. For Home Manager or nix-darwin
  code, also look for that project's local sources.
- Consult the flake-parts source before writing or editing any flake code.

### Code style

- Prefer Nixpkgs `lib` over `builtins` and namespaced helpers (`lib.foo.bar`)
  over top-level aliases (`lib.fooBar`) where equivalents exist.
- Prefer `finalAttrs` callbacks over `let ... in ...` where possible. Never
  use `rec`. Use `let ... in ...` instead.
- Never use `with`. Bind names explicitly, e.g. `inherit (lib) ...;`.

### Packages and scripts

- Add `passthru.updateScript` to new local packages when possible. Prefer
  `nix-update-script`, with `common-updater-scripts` as the fallback.
- Prefer `writeShellApplication` for Bash and `pkgs.writers.writePython3Bin`
  for Python. Use `pkgs.writers.writePython3` for a standalone executable file.
- Prefer `symlinkJoin` to handwritten `ln -s` loops when merging package
  output trees. Use `linkFarm` for explicitly named symlinks.
- Use `lib.meta.getExe` for `meta.mainProgram` and `lib.meta.getExe'` for a
  named executable. Avoid top-level aliases and handwritten `/bin/` paths.

### Documenting custom functions

Follow the [Nixpkgs style][nixdoc-style]. Put `/** ... */` directly above the
binding. Summarize behavior and constraints, list inputs in call order (with
required fields and defaults), and show the signature with `::` and `->`.
Show a call and its result with `=>`, plus a default or edge case if useful.

[nixdoc-style]: https://redirect.github.com/NixOS/nixpkgs/blob/master/lib/README.md#reference-documentation

#### Template

````nix
/**
  Describe what the function does and any behavior callers need to know

  # Inputs

  `arg`

  : Explain what the argument means and any constraints

  # Type

  ```
  functionName :: InputType -> OutputType
  ```

  # Examples
  :::{.example}
  ## `functionName` usage example

  ```nix
  functionName input
  => result
  ```

  :::
*/
````

#### Example: curried arguments

````nix
/**
  Qualify a name with a namespace, leaving it unchanged if the namespace is empty

  # Inputs

  `namespace`

  : Prefix to place before the name, or `""` to leave it unqualified

  `name`

  : Name to qualify

  # Type

  ```
  qualifyName :: String -> String -> String
  ```

  # Examples
  :::{.example}
  ## `qualifyName` usage example

  ```nix
  qualifyName "tools" "lint"
  => "tools/lint"
  qualifyName "" "lint"
  => "lint"
  ```

  :::
*/
qualifyName =
  namespace: name:
  if namespace == "" then name else "${namespace}/${name}";
````

#### Example: attribute-set argument with a default

````nix
/**
  Combine a namespace and a name into a cache key

  # Inputs

  `options` (attribute set)

  : `name` (required)
    : Name of the cache entry

    `namespace` (optional, default: `"local"`)
    : Namespace for the cache entry

  # Type

  ```
  mkCacheKey :: { name :: String; namespace :: String ? "local"; } -> String
  ```

  # Examples
  :::{.example}
  ## `mkCacheKey` usage example

  ```nix
  mkCacheKey { name = "build"; }
  => "local:build"
  mkCacheKey { name = "build"; namespace = "ci"; }
  => "ci:build"
  ```

  :::
*/
mkCacheKey =
  { name, namespace ? "local" }:
  "${namespace}:${name}";
````
