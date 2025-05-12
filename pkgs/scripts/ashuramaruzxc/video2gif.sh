#! /usr/bin/env nix-shell
#! nix-shell --pure -i bash -p gifski ffmpeg_7-full parallel fd rename
# shellcheck shell=bash
# FUCK YOU FOR MAKING IT A SHELL SCRIPT, THATS COOL I CANT FUCKING INSTALL WITHOUT --impure flag

set -euo pipefail

usage() {
	echo "Usage: $0 <directory> [-f|--fps <fps> (default: 24)]"
	exit 2
}

parse_args() {
	search_dir=""
	fps=24

	if [[ $# -lt 1 ]]; then
		usage
	fi
	search_dir="$1"
	shift

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--fps | -f)
			shift
			fps="${1:-24}"
			;;
		*)
			usage
			;;
		esac
		shift
	done

	if [[ ! -d "$search_dir" ]]; then
		echo "Error: '$search_dir' is not a directory."
		exit 3
	fi
}

lowercase_extensions() {
	local dir="$1"
	fd . "$dir" -t f | while read -r file; do
		ext="${file##*.}"
		base="${file%.*}"
		if [[ "$file" != "$base.${ext,,}" ]]; then
			mv -- "$file" "$base.${ext,,}"
		fi
	done
}

encode_all_videos() {
	local dir="$1"
	local filters="fps=${fps}"

	# Find all video files (case insensitive)
	mapfile -t files < <(fd . "$dir" -t f -e mp4 -e mov -e webm -e mkv)
	if [[ ${#files[@]} -eq 0 ]]; then
		echo "No video files found in '$dir'."
		return
	fi

	export filters
	export -f encode_video

	parallel --halt soon,fail=1 encode_video {} "$filters" ::: "${files[@]}"
}

encode_video() {
	local file="$1"
	local filters="$2"
	local base="${file%.*}"
	local dst="${base}.gif"
	local tmpdir
	tmpdir=$(mktemp -d)
	trap 'rm -rf "$tmpdir"' RETURN

	if [[ -f $dst ]]; then
		echo "Skipping '$file': '$dst' already exists."
		return 0
	fi

	echo "Encoding '$file' to '$dst'..."

	if ! ffmpeg -v warning -i "$file" -vf "$filters" "$tmpdir/frame%04d.png"; then
		echo "Failed to extract frames from '$file'."
		return 1
	fi

	if ! gifski -o "$dst" "$tmpdir"/frame*.png; then
		echo "Failed to encode GIF for '$file'."
		return 1
	fi

	rm -- "$file"
}

main() {
	parse_args "$@"
	lowercase_extensions "$search_dir"
	encode_all_videos "$search_dir"
}

main "$@"
