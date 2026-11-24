#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

mapfile -d '' workflow_files < <(
  git ls-files -z --cached --others --exclude-standard -- \
    ':(glob).github/workflows/*.yaml' ':(glob).github/workflows/*.yml' \
    ':(glob).github/actions/**/action.yaml' ':(glob).github/actions/**/action.yml'
)

if ((${#workflow_files[@]} == 0)); then
  echo "No GitHub workflows or actions found" >&2
  exit 1
fi

action_refs="$(
  yq -Nr '
    (.jobs[]?.uses, .jobs[]?.steps[]?.uses, .runs.steps[]?.uses,
      (.runs.image | select(tag == "!!str") | select(test("^docker://")))) | select(. != null)
  ' "${workflow_files[@]}" | sort -u
)"

while IFS= read -r action_ref; do
  case "${action_ref}" in
    "" | ./*) continue ;;
    docker://*)
      if [[ ! ${action_ref} =~ @sha256:[0-9a-f]{64}$ ]]; then
        printf 'Docker action is not pinned to a SHA-256 digest: %s\n' \
          "${action_ref}" >&2
        exit 1
      fi
      continue
      ;;
  esac

  if [[ ! ${action_ref} =~ ^([^/[:space:]]+/[^/@[:space:]]+)(/[^@[:space:]]+)?@([0-9a-f]{40})$ ]]; then
    printf 'Action reference is not pinned to a full commit SHA: %s\n' \
      "${action_ref}" >&2
    exit 1
  fi

  repository=${BASH_REMATCH[1]}
  commit=${BASH_REMATCH[3]}
  if ! gh api --silent "repos/${repository}/commits/${commit}"; then
    printf 'Action reference does not resolve to a GitHub commit: %s\n' \
      "${action_ref}" >&2
    exit 1
  fi

  printf 'Verified %s\n' "${action_ref}"
done <<<"${action_refs}"
