#!/usr/bin/env bash
set -euo pipefail

# Release the evaluator heap between hosts while retaining the normal flake
# schemas and checks for every output
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

printf 'null\n' >"${check_dir}/selection.json"
echo '::group::Shared flake outputs'
# Materialize sources and derivations for every system before --no-build
# switches evaluation to read-only mode, including checks absent on this runner
for output in packages checks; do
  nix eval --json "path:${check_dir}#${output}" --apply '
    builtins.mapAttrs (_: packages:
      builtins.mapAttrs (_: package: package.drvPath) packages
    )
  ' >/dev/null
done
nix flake check "path:${check_dir}"
nix flake check "path:${check_dir}" --all-systems --no-build
echo '::endgroup::'

host_metadata="$(nix eval --json "${project_root}#hostMetadata")"
while IFS= read -r host; do
  printf '%s\n' "${host}" >"${check_dir}/selection.json"
  echo "::group::Host $(jq -r .name <<<"${host}")"
  nix flake check "path:${check_dir}"
  echo '::endgroup::'
done < <(jq -c --arg system "${native_system}" \
  'to_entries[] | select(.value.system == $system) | {name: .key, system: .value.system}' \
  <<<"${host_metadata}")
