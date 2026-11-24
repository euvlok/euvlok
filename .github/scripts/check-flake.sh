#!/usr/bin/env bash
set -euo pipefail

# Keep shared builds and host evaluations independently runnable in CI
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
native_system="$(nix config show system)"

check_shared() (
  check_dir="$(mktemp -d)"
  trap 'rm -rf "${check_dir}"' EXIT

  # Use the checkout's tracked source and existing lock without a wrapper lock
  nix flake prefetch --json --out-link "${check_dir}/project-source" "${project_root}" |
    jq -e --arg system "${native_system}" \
      '{project: "path:\(.storePath)?narHash=\(.hash | @uri)", system: $system}' \
      >"${check_dir}/project.json"

  cat >"${check_dir}/flake.nix" <<'NIX'
{
  outputs =
    _:
    let
      settings = builtins.fromJSON (builtins.readFile ./project.json);
      project = builtins.getFlake settings.project;
      lib = project.inputs.nixpkgs.lib;
      perSystemOutputs = [
        "apps"
        "checks"
        "devShells"
        "formatter"
        "legacyPackages"
        "packages"
      ];
      hostOutputs = [
        "nixosConfigurations"
        "darwinConfigurations"
        "nixosBuilds"
        "hostChecks"
        "hostChecksBySystem"
      ];
    in
    lib.attrsets.mapAttrs (
      output: value:
      if lib.lists.elem output perSystemOutputs then
        lib.attrsets.intersectAttrs { ${settings.system} = null; } value
      else
        value
    ) (lib.attrsets.removeAttrs project.outputs hostOutputs);
}
NIX

  echo '::group::Shared flake outputs'
  nix flake check "path:${check_dir}"
  echo '::endgroup::'
)

if [[ "${selection}" != host ]]; then
  check_shared
fi

if [[ "${selection}" != shared ]]; then
  host_metadata="$(nix eval --json --no-update-lock-file "${project_root}#hostMetadata")"
  hosts="$(jq -r --arg system "${native_system}" --arg name "${2:-}" '
    to_entries[] |
    select(if $name == "" then .value.system == $system else .key == $name end) |
    [.key, .value.system] | @tsv
  ' <<<"${host_metadata}")"

  if [[ "${selection}" == host && -z "${hosts}" ]]; then
    echo "Unknown host: $2" >&2
    exit 1
  fi

  while IFS=$'\t' read -r host system; do
    [[ -n "${host}" ]] || continue
    echo "::group::Host ${host} (${system})"
    # Unlike flake check --no-build, eval can materialize sources on a cold store
    drv_path="$(nix eval --raw --no-eval-cache --no-update-lock-file \
      --option allow-import-from-derivation false \
      "${project_root}#hostChecksBySystem.${system}.${host}")"
    printf '%s\n' "${drv_path}"
    echo '::endgroup::'
  done <<<"${hosts}"
fi
