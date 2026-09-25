#!/usr/bin/env bash
# Directory conversion shortcut; removes sources after successful conversion.
set -euo pipefail

if ((BASH_VERSINFO[0] < 5)); then
  printf 'video2gif_simple: Bash 5 or newer is required\n' >&2
  exit 1
fi

main() {
  local directory script_dir
  local -a options=()

  if (($# == 0)) || [[ "$1" == -h || "$1" == --help ]]; then
    printf 'Usage: video2gif_simple DIRECTORY [-f|--fps FPS]\n'
    printf '%s\n' \
      'Converts videos recursively and removes successfully encoded sources'
    return 0
  fi
  directory="$1"
  shift
  while (($# > 0)); do
    case "$1" in
      -f | --fps)
        if (($# < 2)); then
          printf 'video2gif_simple: --fps requires a value\n' >&2
          return 1
        fi
        options+=(--fps "$2")
        shift 2
        ;;
      *)
        printf 'video2gif_simple: unknown option: %s\n' "$1" >&2
        return 1
        ;;
    esac
  done

  script_dir="${BASH_SOURCE[0]%/*}"
  if [[ -f "${script_dir}/video2gif.sh" ]]; then
    exec "${BASH}" "${script_dir}/video2gif.sh" \
      --directory "${directory}" --remove "${options[@]}"
  fi
  exec video2gif --directory "${directory}" --remove "${options[@]}"
}

main "$@"
