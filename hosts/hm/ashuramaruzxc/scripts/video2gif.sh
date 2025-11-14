#!/usr/bin/env nix-shell
#!nix-shell --pure -i bash -p gifski ffmpeg_7-full parallel fd
# shellcheck shell=bash

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════════

readonly SCRIPT_NAME="video2gif"
# shellcheck disable=SC2034
readonly VERSION="1.0.0"

# Default values
readonly DEFAULT_FPS=24
readonly DEFAULT_QUALITY=90
readonly MIN_QUALITY=1
readonly MAX_QUALITY=100

# Supported video extensions
readonly -a VIDEO_EXTENSIONS=(mp4 mov webm mkv)

# shellcheck disable=SC2034
readonly COLOR_RESET='\033[0m'
# shellcheck disable=SC2034
readonly COLOR_RED='\033[0;31m'
# shellcheck disable=SC2034
readonly COLOR_GREEN='\033[0;32m'
# shellcheck disable=SC2034
readonly COLOR_YELLOW='\033[0;33m'
# shellcheck disable=SC2034
readonly COLOR_BLUE='\033[0;34m'

# ═══════════════════════════════════════════════════════════════════
# GLOBAL VARIABLES
# ═══════════════════════════════════════════════════════════════════

declare -a input_files=()
directory_mode=false
search_dir=""
fps=$DEFAULT_FPS
quality=$DEFAULT_QUALITY
remove_source=false
output_path=""
parallel_jobs=""

# ═══════════════════════════════════════════════════════════════════
# OUTPUT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

log_info() {
	echo "[~] $*"
}

log_success() {
	echo "[OK] $*"
}

log_error() {
	echo "[!!] Error: $*" >&2
}

log_skip() {
	echo "[SKIP] $*"
}

log_process() {
	echo "[>>] $*"
}

print_banner() {
	cat <<'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ██╗   ██╗██╗██████╗ ███████╗ ██████╗  ██████╗ ██╗███████╗   ║
║   ██║   ██║██║██╔══██╗██╔════╝██╔═══██╗██╔════╝ ██║██╔════╝   ║
║   ██║   ██║██║██║  ██║█████╗  ██║   ██║╚█████╗  ██║█████╗     ║
║   ╚██╗ ██╔╝██║██║  ██║██╔══╝  ██║   ██║ ╚═══██╗ ██║██╔══╝     ║
║    ╚████╔╝ ██║██████╔╝███████╗╚██████╔╝██████╔╝ ██║██║        ║
║     ╚═══╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝  ╚═╝╚═╝        ║
║                                                                  ║
║              High-Quality Video to GIF Converter                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
}

print_separator() {
	echo "────────────────────────────────────────────────────────────"
}

print_summary_box() {
	local total=$1
	cat <<EOF
┌────────────────────────────────────────────────────────────┐
│ Files to process: $total
│ FPS: $fps | Quality: $quality | Remove source: $remove_source
│ Parallel jobs: ${parallel_jobs:-auto}
└────────────────────────────────────────────────────────────┘
EOF
}

print_completion_box() {
	local elapsed=$1
	local count=$2
	cat <<EOF

╔══════════════════════════════════════════════════════════════╗
║                    CONVERSION COMPLETE!                      ║
║  Total time: ${elapsed}s | Processed: ${count} file(s)              ║
╚══════════════════════════════════════════════════════════════╝
EOF
}

# ═══════════════════════════════════════════════════════════════════
# HELP & USAGE
# ═══════════════════════════════════════════════════════════════════

usage() {
	cat <<-EOF
		Usage: $SCRIPT_NAME [FILES...] [OPTIONS]
		       $SCRIPT_NAME --directory <dir> [OPTIONS]

		Convert video files to high-quality GIF format.

		MODES:
		  FILES...              Convert specific video files
		  -d, --directory DIR   Convert all videos in directory

		OPTIONS:
		  -f, --fps <fps>        Set output FPS (default: $DEFAULT_FPS)
		  -q, --quality <1-100>  Set GIF quality (default: $DEFAULT_QUALITY)
		  -o, --output <path>    Output path/directory (optional)
		  -r, --remove           Remove source files after conversion
		  -j, --jobs <N>         Parallel jobs (default: auto)
		  -h, --help             Show this help message

		EXAMPLES:
		  # Convert single file
		  $SCRIPT_NAME video.mp4
		  
		  # Convert with custom quality
		  $SCRIPT_NAME video.mp4 --fps 30 --quality 95
		  
		  # Convert all videos in directory
		  $SCRIPT_NAME --directory ~/Videos --fps 30
		  
		  # Custom output location
		  $SCRIPT_NAME video.mp4 -o output.gif

		Supported formats: ${VIDEO_EXTENSIONS[*]}
	EOF
	exit 0
}

# ═══════════════════════════════════════════════════════════════════
# VALIDATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

check_dependencies() {
	local -a missing_tools=()
	local -a required_tools=(ffmpeg gifski parallel fd)

	for tool in "${required_tools[@]}"; do
		if ! command -v "$tool" &>/dev/null; then
			missing_tools+=("$tool")
		fi
	done

	if [[ ${#missing_tools[@]} -gt 0 ]]; then
		log_error "Missing required tools: ${missing_tools[*]}"
		echo "This script should be run with nix-shell (see shebang)."
		exit 1
	fi
}

validate_number() {
	local value=$1
	local name=$2

	if [[ -z "$value" ]] || ! [[ "$value" =~ ^[0-9]+$ ]]; then
		log_error "$name requires a numeric argument"
		exit 1
	fi
}

validate_quality() {
	local value=$1

	if [[ -z "$value" ]] || ! [[ "$value" =~ ^[0-9]+$ ]] ||
		[[ "$value" -lt $MIN_QUALITY || "$value" -gt $MAX_QUALITY ]]; then
		log_error "--quality requires a number between $MIN_QUALITY and $MAX_QUALITY"
		exit 1
	fi
}

validate_file() {
	local file=$1

	if [[ ! -f "$file" ]]; then
		log_error "File not found: '$file'"
		exit 1
	fi
}

validate_directory() {
	local dir=$1

	if [[ ! -d "$dir" ]]; then
		log_error "'$dir' is not a directory"
		exit 1
	fi
}

# ═══════════════════════════════════════════════════════════════════
# ARGUMENT PARSING
# ═══════════════════════════════════════════════════════════════════

parse_args() {
	[[ $# -eq 0 ]] && usage

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-d | --directory)
			shift
			[[ -z "${1:-}" ]] && {
				log_error "--directory requires an argument"
				exit 1
			}
			directory_mode=true
			search_dir="$1"
			validate_directory "$search_dir"
			;;
		-f | --fps)
			shift
			validate_number "${1:-}" "--fps"
			fps="$1"
			;;
		-q | --quality)
			shift
			validate_quality "${1:-}"
			quality="$1"
			;;
		-o | --output)
			shift
			[[ -z "${1:-}" ]] && {
				log_error "--output requires an argument"
				exit 1
			}
			output_path="$1"
			;;
		-r | --remove)
			remove_source=true
			;;
		-j | --jobs)
			shift
			validate_number "${1:-}" "--jobs"
			parallel_jobs="$1"
			;;
		-h | --help)
			usage
			;;
		-*)
			log_error "Unknown option '$1'"
			usage
			;;
		*)
			validate_file "$1"
			input_files+=("$1")
			;;
		esac
		shift
	done

	validate_args
}

validate_args() {
	if [[ "$directory_mode" == true ]] && [[ ${#input_files[@]} -gt 0 ]]; then
		log_error "Cannot use both --directory and file arguments"
		exit 1
	fi

	if [[ "$directory_mode" == false ]] && [[ ${#input_files[@]} -eq 0 ]]; then
		log_error "No input files specified"
		usage
	fi

	if [[ -n "$output_path" ]] && [[ ${#input_files[@]} -gt 1 ]]; then
		log_error "--output can only be used with a single input file"
		exit 1
	fi
}

# ═══════════════════════════════════════════════════════════════════
# FILE OPERATIONS
# ═══════════════════════════════════════════════════════════════════

build_extension_pattern() {
	local pattern=""
	for ext in "${VIDEO_EXTENSIONS[@]}"; do
		pattern+=" -e $ext -e ${ext^^}"
	done
	echo "$pattern"
}

normalize_extensions() {
	local dir="$1"
	local count=0
	local ext_pattern

	ext_pattern=$(build_extension_pattern)

	log_info "Normalizing file extensions..."

	# shellcheck disable=SC2086
	while IFS= read -r file; do
		ext="${file##*.}"
		base="${file%.*}"
		lower_ext="${ext,,}"

		if [[ "$file" != "$base.$lower_ext" ]]; then
			mv -v -- "$file" "$base.$lower_ext"
			((count++)) || true
		fi
	done < <(fd . "$dir" -t f $ext_pattern)

	if [[ $count -gt 0 ]]; then
		log_success "Normalized $count file extension(s)"
	else
		log_success "All extensions already normalized"
	fi
	echo
}

find_videos_in_directory() {
	local dir="$1"
	local ext_args=""

	for ext in "${VIDEO_EXTENSIONS[@]}"; do
		ext_args+=" -e $ext"
	done

	# shellcheck disable=SC2086
	mapfile -t input_files < <(fd . "$dir" -t f $ext_args)
}

get_file_size() {
	du -h "$1" | cut -f1
}

# ═══════════════════════════════════════════════════════════════════
# VIDEO PROCESSING
# ═══════════════════════════════════════════════════════════════════

extract_frames() {
	local input="$1"
	local tmpdir="$2"
	local filters="fps=${fps}"

	ffmpeg -hide_banner -loglevel error \
		-i "$input" \
		-vf "$filters" \
		"$tmpdir/frame%04d.png" 2>&1
}

create_gif() {
	local tmpdir="$1"
	local output="$2"

	gifski --quality "$quality" \
		--fps "$fps" \
		-o "$output" \
		"$tmpdir"/frame*.png 2>&1
}

cleanup_temp() {
	local tmpdir="$1"
	[[ -d "$tmpdir" ]] && rm -rf "$tmpdir"
}

handle_completion() {
	local input="$1"
	local output="$2"
	local input_size="$3"
	local output_size="$4"

	if [[ "$remove_source" == true ]]; then
		rm -- "$input"
		log_success "$input ($input_size) -> $output ($output_size) [source removed]"
	else
		log_success "$input ($input_size) -> $output ($output_size) [source kept]"
	fi
}

encode_video() {
	local input="$1"
	local output="$2"
	local tmpdir

	# Skip if output exists
	if [[ -f "$output" ]]; then
		log_skip "'$input' -> output already exists"
		return 0
	fi

	# Create temporary directory
	tmpdir=$(mktemp -d)
	trap 'cleanup_temp "$tmpdir"' EXIT

	log_process "Processing: $input"

	# Extract frames
	if ! extract_frames "$input" "$tmpdir"; then
		log_error "Failed to extract frames from '$input'"
		cleanup_temp "$tmpdir"
		return 1
	fi

	# Verify frames were created
	if ! compgen -G "$tmpdir/frame*.png" >/dev/null; then
		log_error "No frames extracted from '$input'"
		cleanup_temp "$tmpdir"
		return 1
	fi

	# Create GIF
	if ! create_gif "$tmpdir" "$output"; then
		log_error "Failed to encode GIF for '$input'"
		cleanup_temp "$tmpdir"
		return 1
	fi

	cleanup_temp "$tmpdir"

	# Report completion
	local input_size output_size
	input_size=$(get_file_size "$input")
	output_size=$(get_file_size "$output")

	handle_completion "$input" "$output" "$input_size" "$output_size"
	return 0
}

# ═══════════════════════════════════════════════════════════════════
# BATCH PROCESSING
# ═══════════════════════════════════════════════════════════════════

get_output_filename() {
	local input="$1"
	echo "$(dirname "$input")/$(basename "$input" | sed 's/\.[^.]*$/.gif/')"
}

process_single_file() {
	local input="${input_files[0]}"
	local output="${output_path:-${input%.*}.gif}"

	encode_video "$input" "$output"
}

process_multiple_files() {
	local job_args="${parallel_jobs:+-j $parallel_jobs}"

	# Export for parallel
	export fps quality remove_source
	export -f encode_video extract_frames create_gif cleanup_temp
	export -f handle_completion get_file_size get_output_filename
	export -f log_info log_success log_error log_skip log_process

	# shellcheck disable=SC2086
	parallel --halt now,fail=1 --line-buffer $job_args \
		encode_video {} "$(get_output_filename {})" \
		::: "${input_files[@]}"
}

process_files() {
	local total=${#input_files[@]}

	if [[ $total -eq 0 ]]; then
		log_error "No video files to process"
		return 1
	fi

	print_summary_box "$total"
	echo

	if [[ $total -eq 1 ]]; then
		process_single_file
	else
		process_multiple_files
	fi
}

# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════

main() {
	check_dependencies

	print_banner
	echo

	parse_args "$@"

	# Handle directory mode
	if [[ "$directory_mode" == true ]]; then
		log_info "Directory mode: $search_dir"
		echo
		normalize_extensions "$search_dir"
		find_videos_in_directory "$search_dir"
	fi

	# Process files
	local start_time end_time elapsed
	start_time=$(date +%s)

	process_files

	end_time=$(date +%s)
	elapsed=$((end_time - start_time))

	print_completion_box "$elapsed" "${#input_files[@]}"
}

# ═══════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════════

main "$@"
