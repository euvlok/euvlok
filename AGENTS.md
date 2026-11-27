# Repository guidance

AI agents may edit this file only with explicit human permission.

## Local version control

- Commit all your work. Use `scope: summary` subjects, such as `ci: fix checks`.
- Explain only why the change was made. Link relevant issues and PRs. Omit
  verification notes.

## GitHub

- Never push to `master`.
- Get approval before any GitHub mutation. Get the proposed title and body
  approved before opening a PR or changing either.
- Use only `gh` for GitHub reads and writes. If no dedicated command exists,
  use `gh api`. If `gh` can't perform the operation, report the blocker.
- Use `redirect.github.com` for GitHub links.

### Open a bot PR

The [Open PR workflow](.github/workflows/open-pr.yml) opens a PR as
`github-actions[bot]` against `master` using the repository template.

1. Check that the workflow is on both `master` and the feature branch.
2. Get approval, then publish the feature branch.
3. Dispatch the workflow with the approved title. Add `-f body="$body"` only if
   the user requests extra text.

   ```sh
   gh workflow run open-pr.yml -R euvlok/euvlok --ref "$branch" -f title="$title"
   ```

4. If the dispatch returns no URL, find the run for the dispatched SHA with
   `gh run list -w open-pr.yml -b "$branch"`. Don't dispatch again.
5. Track CI with `gh run watch "$run_id" --exit-status`. Inspect failures
   with `gh run view "$run_id" --log-failed`.

### Check PR status and reviews

- Prefer `--json` and `--jq`. For `gh pr checks --json bucket,name,link`, read
  `bucket`, not the exit code.
- Fetch inline review comments with
  `gh api --paginate "repos/euvlok/euvlok/pulls/$pr/comments"`.
- To wait for PR events, get approval for the subscription, then use
  `gh event listen` as described in the [official `gh` skill][gh-skill].

[gh-skill]: https://redirect.github.com/cli/cli/blob/HEAD/skills/gh/SKILL.md

## Documentation

Create Markdown files or edit `README.md` only when explicitly asked.

## Formatting

- Format commit prose and new or edited code comments with `rumdl fmt`. Enable
  `MD013` prose reflow at 80 columns. Keep subjects on one line and add
  trailers after formatting.
- Pass comment text to `rumdl fmt --stdin --silent` without comment markers
  or source indentation. Restore both afterward.

## Nix preferences

### Before writing Nix

- Look for local Nixpkgs sources. For Home Manager or nix-darwin code, also
  consult that project's local sources.
- Consult the flake-parts source before writing or editing any flake code.

### Code style

- Prefer Nixpkgs `lib` over `builtins`. Prefer namespaced helpers
  (`lib.foo.bar`) over equivalent top-level aliases (`lib.fooBar`).
- Prefer `finalAttrs` callbacks to `let ... in ...` where possible. Use
  `let ... in ...` instead of `rec`.
- Bind names explicitly (for example, `inherit (lib) ...;`). Don't use `with`.

### Packages and scripts

- Add `passthru.updateScript` to new local packages when possible. Prefer
  `nix-update-script`, with `common-updater-scripts` as the fallback.
- Prefer `writeShellApplication` for Bash and `pkgs.writers.writePython3Bin`
  for Python. Use `pkgs.writers.writePython3` for a standalone executable file.
- Prefer `symlinkJoin` to handwritten `ln -s` loops when merging package
  output trees. Use `linkFarm` for explicitly named symlinks.
- Use `lib.meta.getExe` for `meta.mainProgram` and `lib.meta.getExe'` for a
  named executable. Avoid top-level aliases and handwritten `/bin/` paths.

### Document custom functions

Put a `/** ... */` comment directly above the binding. Describe what the
function does and any constraints. List inputs in call order, with required
fields and defaults. Write the signature with `::` and `->`. Show a call and
its result with `=>`. Add a default or edge case if useful.

See the [Nixpkgs doc-comment example][nixdoc-example] for the format.

[nixdoc-example]: https://redirect.github.com/NixOS/nixpkgs/blob/5443877a69b93421b165477bfd673b673065aebe/lib/strings.nix#L66-L94
