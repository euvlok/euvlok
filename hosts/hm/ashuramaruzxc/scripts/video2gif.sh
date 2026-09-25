#!/usr/bin/env bash
# Convert videos to GIFs with ffmpeg and gifski.
# Requires Bash 5+, GNU coreutils, fd and GNU Parallel.
set -euo pipefail

if ((BASH_VERSINFO[0] < 5)); then
  printf 'video2gif: Bash 5 or newer is required\n' >&2
  exit 1
fi

# Print a diagnostic and exit unsuccessfully.
die() {
  printf 'video2gif: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
  Usage: video2gif [options] FILE...
        video2gif --directory DIR [options]

  -d, --directory DIR  Recursively find MP4, MOV, WebM and MKV files
  -f, --fps N          Frames per second (default: 24; positive integer)
  -q, --quality N      GIF quality from 1 to 100 (default: 90)
  -o, --output FILE    Output path for a single input (default: beside input)
  -r, --remove         Delete sources only after successful conversion
  -j, --jobs N         Parallel jobs (default: CPU count; 0 means unlimited)
  -h, --help           Show this help
  --                   Treat remaining arguments as filenames
EOF
}

# Encode in a subshell so traps and temporary files belong to this job.
# Arguments: fps, quality, remove_source, input, output.
encode_video() (
  set -euo pipefail
  local fps="$1" quality="$2" remove_source="$3" input="$4" output="$5"
  local work_dir
  local -a frames

  if [[ -e "${output}" || -L "${output}" ]]; then
    printf 'Skipping existing output: %s\n' "${output}"
    return 0
  fi

  # Stage on the destination filesystem for atomic, no-clobber publication.
  work_dir=$(mktemp -d -- "${output%/*}/.video2gif.XXXXXXXXXX")
  trap 'rm -rf -- "${work_dir}"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP

  printf 'Converting: %s\n' "${input}"
  ffmpeg -nostdin -hide_banner -loglevel error -i "${input}" \
    -vf "fps=${fps}" "${work_dir}/frame%010d.png" \
    || die "Failed to extract frames: ${input}"

  shopt -s nullglob
  frames=("${work_dir}"/frame*.png)
  ((${#frames[@]} > 0)) || die "No frames extracted: ${input}"
  gifski --quiet --quality "${quality}" --fps "${fps}" \
    -o "${work_dir}/output.gif" "${frames[@]}" \
    || die "Failed to encode GIF: ${input}"
  [[ -s "${work_dir}/output.gif" ]] || die "Empty GIF: ${input}"

  # A competing conversion must not overwrite an output or delete our source.
  ln -T -- "${work_dir}/output.gif" "${output}" \
    || die "Could not publish GIF (source kept): ${output}"
  if [[ "${remove_source}" == true ]]; then
    rm -- "${input}"
  fi
  printf 'Created: %s\n' "${output}"
)

# Parse arguments, validate the complete batch, and dispatch conversion jobs.
main() {
  local fps=24 quality=90 jobs='' directory='' output='' remove_source=false
  local option value input destination filename tool index
  local -a inputs=() outputs=() job_args=()
  local -A destinations=()

  if (($# == 0)); then
    usage
    return 0
  fi

  while (($# > 0)); do
    case "$1" in
      -h | --help)
        usage
        return 0
        ;;
      -d | --directory | -f | --fps | -q | --quality | -o | --output | \
        -j | --jobs)
        option="$1"
        (($# >= 2)) && [[ -n "$2" ]] \
          || die "${option} requires a value"
        value="$2"
        case "${option}" in
          -d | --directory) directory="${value}" ;;
          -o | --output) output="${value}" ;;
          *)
            # Bound decimal input before arithmetic; avoid octal and overflow.
            [[ "${value}" =~ ^[0-9]{1,9}$ ]] \
              || die "${option} requires an integer of at most 9 digits"
            value=$((10#${value}))
            case "${option}" in
              -f | --fps) fps="${value}" ;;
              -q | --quality) quality="${value}" ;;
              -j | --jobs) jobs="${value}" ;;
            esac
            ;;
        esac
        shift 2
        ;;
      -r | --remove)
        remove_source=true
        shift
        ;;
      --)
        shift
        inputs+=("$@")
        break
        ;;
      -*) die "Unknown option: $1 (see --help)" ;;
      *)
        inputs+=("$1")
        shift
        ;;
    esac
  done

  ((fps > 0)) || die '--fps must be positive'
  ((quality >= 1 && quality <= 100)) \
    || die '--quality must be between 1 and 100'
  if [[ -n "${directory}" ]]; then
    ((${#inputs[@]} == 0)) \
      || die 'Cannot combine --directory with file arguments'
    [[ -d "${directory}" ]] || die "Not a directory: ${directory}"
  fi
  for tool in ffmpeg gifski realpath mktemp ln rm; do
    command -v "${tool}" >/dev/null || die "Missing dependency: ${tool}"
  done

  if [[ -n "${directory}" ]]; then
    command -v fd >/dev/null || die 'Missing dependency: fd'
    mapfile -d '' -t inputs < <(
      fd --type f --ignore-case --print0 \
        -e mp4 -e mov -e webm -e mkv -- . "${directory}"
    )
    # mapfile cannot report producer errors; $! is the substitution's PID.
    wait "$!" || die "Could not search directory: ${directory}"
  fi

  ((${#inputs[@]} > 0)) || die 'No input videos found'
  if [[ -n "${output}" ]] && ((${#inputs[@]} != 1)); then
    die '--output requires exactly one input video'
  fi

  for index in "${!inputs[@]}"; do
    input="${inputs[index]}"
    [[ -f "${input}" ]] || die "Not a file: ${input}"
    # Absolute paths also prevent option/protocol interpretation by encoders.
    # Preserve symlinks so --remove deletes the supplied name, not its target.
    if [[ "${input}" != /* ]]; then
      input="${PWD}/${input}"
    fi
    inputs[index]="${input}"
    filename="${input##*/}"
    destination="${output:-${input%/*}/${filename%.*}.gif}"
    if [[ "${destination}" != /* ]]; then
      destination="${PWD}/${destination}"
    fi
    # NUL-delimited read preserves trailing newlines and fails on empty output.
    IFS= read -r -d '' value < <(realpath -zm -- "${destination}")
    [[ -z "${destinations[${value}]:-}" ]] \
      || die "Multiple inputs would write: ${destination}"
    destinations["${value}"]=1
    outputs+=("${destination}")
  done

  if ((${#inputs[@]} == 1)); then
    encode_video "${fps}" "${quality}" "${remove_source}" \
      "${inputs[0]}" "${outputs[0]}"
  else
    command -v parallel >/dev/null || die 'Missing dependency: parallel'
    if [[ -n "${jobs}" ]]; then
      job_args=(--jobs "${jobs}")
    fi
    # GNU Parallel launches Bash explicitly; login SHELL may be zsh or fish.
    export -f encode_video die
    SHELL="${BASH}" PARALLEL_SHELL="${BASH}" parallel --plain --null \
      --halt soon,fail=1 --line-buffer "${job_args[@]}" \
      encode_video "${fps}" "${quality}" "${remove_source}" '{1}' '{2}' \
      ::: "${inputs[@]}" :::+ "${outputs[@]}"
  fi
}

# Defer signal handling until the foreground worker has finished its cleanup.
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
main "$@"
