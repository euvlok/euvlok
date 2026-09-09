#!/usr/bin/env bash
set -euo pipefail

# Release the evaluator heap between hosts while retaining the normal flake
# schemas and checks for every output.
project_root="$(git rev-parse --show-toplevel)"
check_dir="$(mktemp -d)"
trap 'rm -rf "${check_dir}"' EXIT

cat >"${check_dir}/flake.nix" <<'NIX'
{
  inputs.project.url = "path:PROJECT_ROOT";
  outputs = { project, ... }:
    let
      selection = builtins.fromJSON (builtins.readFile ./selection.json);
      hostOutputs = [
        "nixosConfigurations"
        "darwinConfigurations"
        "nixosBuilds"
        "hostChecks"
        "hostChecksBySystem"
      ];
      selectHost = name: builtins.intersectAttrs { ${name} = null; };
    in
    if selection == null then
      builtins.removeAttrs project.outputs hostOutputs
    else
      { schemas = project.schemas; }
      // builtins.listToAttrs (map (output: {
        name = output;
        value = selectHost selection.name project.${output};
      }) (builtins.filter (output: output != "hostChecksBySystem") hostOutputs))
      // {
        hostChecksBySystem.${selection.system} =
          selectHost selection.name project.hostChecksBySystem.${selection.system};
      };
}
NIX

# JSON strings are valid Nix strings once interpolation markers are escaped.
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
nix --extra-experimental-features parallel-eval --option eval-cores 1 \
  flake check "path:${check_dir}" --all-systems
echo '::endgroup::'

host_metadata="$(nix eval --json "${project_root}#hostMetadata")"
while IFS= read -r host; do
  printf '%s\n' "${host}" >"${check_dir}/selection.json"
  echo "::group::Host $(jq -r .name <<<"${host}")"
  nix --extra-experimental-features parallel-eval --option eval-cores 1 \
    flake check "path:${check_dir}" --all-systems
  echo '::endgroup::'
done < <(jq -c 'to_entries[] | {name: .key, system: .value.system}' <<<"${host_metadata}")
