#!/usr/bin/env bash
# shellcheck shell=bash
#
# Select an NVIDIA Unix driver published for both x86_64 and aarch64,
# then rewrite packages/nvidia-driver.nix with nix-update.
set -euo pipefail
shopt -s inherit_errexit

readonly X86_INDEX='https://download.nvidia.com/XFree86/Linux-x86_64/'
readonly AARCH64_INDEX='https://download.nvidia.com/XFree86/Linux-aarch64/'
readonly CURRENT_VERSION='@currentVersion@'
readonly DRIVER_NIX='packages/nvidia-driver.nix'

err() {
  printf 'error: %s\n' "$*" >&2
}

info() {
  printf 'info: %s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: nvidia-prefetch [version] [nix-update-args...]

Select an NVIDIA Unix driver published for both x86_64 and aarch64, then
rewrite packages/nvidia-driver.nix with nix-update.

Options:
  -h, --help       Show this help
  -n, --no-update  Print the selected version and exit
EOF
}

is_version() {
  [[ "$1" =~ ^[0-9]+(\.[0-9]+)+$ ]]
}

# Print dotted NVIDIA directory versions from a download index.
# NVIDIA's indexes emit href='610.43.03/' (single quotes). The extra
# dotted-segment keeps junk like 1.0-4499/ out of the list.
# Arguments:
#   NVIDIA XFree86 directory index URL
# Outputs:
#   One version per line on stdout
list_versions() {
  local url="$1"
  local html
  local remaining

  html="$(curl -fsSL "${url}")"
  remaining="${html}"
  while [[ "${remaining}" =~ href=\'([0-9]+(\.[0-9]+)+)/\' ]]; do
    printf '%s\n' "${BASH_REMATCH[1]}"
    remaining="${remaining#*"${BASH_REMATCH[0]}"}"
  done
}

# Print the newest dotted version published for both architectures.
# Globals:
#   X86_INDEX
#   AARCH64_INDEX
# Outputs:
#   One version on stdout
latest_shared() {
  local x86_list
  local aarch64_list

  x86_list="$(list_versions "${X86_INDEX}")"
  aarch64_list="$(list_versions "${AARCH64_INDEX}")"

  comm -12 \
    <(sort -u <<<"${x86_list}") \
    <(sort -u <<<"${aarch64_list}") \
    | sort -V \
    | tail -n1
}

require_euvlok_root() {
  local root

  if ! root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    err "run nvidia-prefetch from the euvlok repository"
    exit 1
  fi
  if [[ ! -f "${root}/${DRIVER_NIX}" ]]; then
    err "${root} is not an euvlok checkout"
    exit 1
  fi
  printf '%s\n' "${root}"
}

main() {
  local no_update=0
  local requested=''
  local version
  local newest
  local root
  local -a passthrough=()
  local -a update_args

  while (($# > 0)); do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      -n | --no-update)
        no_update=1
        shift
        ;;
      --)
        shift
        passthrough+=("$@")
        break
        ;;
      -*)
        passthrough+=("$1")
        shift
        ;;
      *)
        if [[ -z "${requested}" ]] && is_version "$1"; then
          requested="$1"
        else
          passthrough+=("$1")
        fi
        shift
        ;;
    esac
  done

  root="$(require_euvlok_root)"
  if ! cd "${root}"; then
    err "unable to enter ${root}"
    exit 1
  fi

  if [[ -n "${requested}" ]]; then
    version="${requested}"
  else
    version="$(latest_shared)"
    if [[ -z "${version}" ]]; then
      err "no shared NVIDIA driver version found for x86_64 and aarch64"
      exit 1
    fi
  fi

  newest="$(
    printf '%s\n' "${CURRENT_VERSION}" "${version}" | sort -V | tail -n1
  )"
  if [[ "${newest}" != "${version}" && -z "${requested}" ]]; then
    err "refusing to downgrade NVIDIA driver from ${CURRENT_VERSION}" \
      "to ${version}"
    err "pass the version explicitly if the downgrade is intentional"
    exit 1
  fi

  info "NVIDIA driver ${CURRENT_VERSION} -> ${version}"

  if ((no_update)); then
    return 0
  fi

  # Substituted by packages/nvidia-prefetch.nix into a quoted argv.
  # shellcheck disable=SC2206
  update_args=(@updateArgs@)

  exec nix-update \
    "${update_args[@]}" \
    --version "${version}" \
    nvidia-driver \
    "${passthrough[@]}"
}

main "$@"
