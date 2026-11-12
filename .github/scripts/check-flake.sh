#!/usr/bin/env bash
set -euo pipefail

# Keep shared checks and native hosts independently runnable in CI
selection="${1:-all}"
case "${selection}" in
  all | shared) ;;
  host)
    if [[ $# != 2 || -z "$2" ]]; then
      echo "Usage: $0 [all|shared|host NAME]" >&2
      exit 2
    fi
    ;;
  *)
    echo "Usage: $0 [all|shared|host NAME]" >&2
    exit 2
    ;;
esac

project_root="$(git rev-parse --show-toplevel)"
native_system="$(nix config show --json | jq -r .system.value)"
check_dir="$(mktemp -d)"
trap 'rm -rf "${check_dir}"' EXIT

cat >"${check_dir}/flake.nix" <<'NIX'
{
  inputs.project.url = "path:PROJECT_ROOT";
  outputs =
    { project, ... }:
    let
      lib = project.inputs.nixpkgs.lib;
      selection = lib.trivial.importJSON ./selection.json;
      hostOutputs = [
        "nixosConfigurations"
        "darwinConfigurations"
        "nixosBuilds"
        "hostChecks"
        "hostChecksBySystem"
      ];
      selectHost = name: lib.attrsets.intersectAttrs { ${name} = null; };
    in
    if selection == null then
      lib.attrsets.removeAttrs project.outputs hostOutputs
    else
      {
        schemas = project.schemas;
      }
      // lib.attrsets.genAttrs (lib.lists.remove "hostChecksBySystem" hostOutputs) (
        output: selectHost selection.name project.${output}
      )
      // {
        hostChecksBySystem.${selection.system} =
          selectHost selection.name
            project.hostChecksBySystem.${selection.system};
      };
}
NIX

# JSON strings are valid Nix strings once interpolation markers are escaped
PROJECT_ROOT="${project_root}" CHECK_DIR="${check_dir}" python3 - <<'PY'
import json
import os
from pathlib import Path

flake = Path(os.environ["CHECK_DIR"]) / "flake.nix"
url = json.dumps("path:" + os.environ["PROJECT_ROOT"]).replace("${", r"\${")
flake.write_text(flake.read_text().replace('"path:PROJECT_ROOT"', url))
PY

if [[ "${selection}" != host ]]; then
  printf 'null\n' >"${check_dir}/selection.json"
  echo '::group::Shared flake outputs'
  nix flake check "path:${check_dir}"
  echo '::endgroup::'
fi

if [[ "${selection}" != shared ]]; then
  host_metadata="$(nix eval --json "${project_root}#hostMetadata")"
  hosts="$(jq -c --arg system "${native_system}" \
    --arg name "${2:-}" \
    'to_entries[] | select(.value.system == $system) |
      select($name == "" or .key == $name) |
      {name: .key, system: .value.system}' <<<"${host_metadata}")"

  if [[ "${selection}" == host && -z "${hosts}" ]]; then
    echo "Host $2 is not native to ${native_system}" >&2
    exit 1
  fi

  while IFS= read -r host; do
    [[ -n "${host}" ]] || continue
    printf '%s\n' "${host}" >"${check_dir}/selection.json"
    echo "::group::Host $(jq -r .name <<<"${host}")"
    nix flake check "path:${check_dir}"
    echo '::endgroup::'
  done <<<"${hosts}"
fi
