#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq nix-update ripgrep sd
# shellcheck shell=bash
#
# Author: FlameFlag
#
#/ Usage: SCRIPTNAME [OPTIONS]... <nix-file>
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message.
#/   --version <version>
#/                Specify version for nix-update (default: branch).
#/
#/ EXAMPLES
#/   # Update a package using the default branch version
#/   SCRIPTNAME pkgs/yt-dlp.nix
#/
#/   # Update a package to a specific version
#/   SCRIPTNAME --version "1.1.0" pkgs/yt-dlp.nix

set -euo pipefail

#{{{ Variables

# Split on newlines and tabs, not spaces.
IFS=$'\t\n'

script_name=$(basename "${0}")
readonly script_name

readonly TEMP_WRAPPER="temp-wrapper.nix"

VERSION="branch"
NIX_FILE=""
ABS_NIX_FILE=""
OWNER=""
REPO=""
#}}}

main() {
	parse_arguments "${@}"
	validate_arguments
	extract_metadata
	update_package

	log_success "Package update completed successfully!"
}

#{{{ Helper functions
log_error() {
	printf "\033[0;31m[error] %s\033[0m\n" "${*}" >&2
}
log_info() {
	printf "\033[0;34m[info] %s\033[0m\n" "${*}"
}
log_success() {
	printf "\033[0;32m[success] %s\033[0m\n" "${*}"
}
log_warning() {
	printf "\033[0;33m[warning] %s\033[0m\n" "${*}"
}

show_help() {
	grep '^#/' <"${BASH_SOURCE[0]}" | cut -c4- | sed "s/SCRIPTNAME/${script_name}/g"
}

cleanup() {
	if [[ -f "${TEMP_WRAPPER}" ]]; then
		rm -f "${TEMP_WRAPPER}"
		log_info "Cleaned up temporary wrapper file."
	fi
}

parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case "${1}" in
		-h | --help)
			show_help
			exit 0
			;;
		--version)
			# Use ${2-} to avoid unbound variable error in strict mode
			if [[ -z "${2-}" ]]; then
				log_error "--version requires a value."
				show_help
				exit 1
			fi
			VERSION="${2}"
			shift 2
			;;
		-*)
			log_error "Unknown option: ${1}"
			show_help
			exit 1
			;;
		*)
			if [[ -z "${NIX_FILE}" ]]; then
				NIX_FILE="${1}"
			else
				log_error "Unexpected argument: '${1}'. A Nix file has already been provided."
				show_help
				exit 1
			fi
			shift
			;;
		esac
	done
}

validate_arguments() {
	if [[ -z "${NIX_FILE}" ]]; then
		log_error "Missing Nix file argument."
		show_help
		exit 1
	fi

	# Convert to absolute path
	local abs_path
	abs_path=$(realpath "${NIX_FILE}")
	ABS_NIX_FILE="${abs_path}"

	if [[ ! -f "${ABS_NIX_FILE}" ]]; then
		log_error "File '${NIX_FILE}' does not exist."
		exit 1
	fi
}

extract_metadata() {
	log_info "Extracting owner and repo from '${ABS_NIX_FILE}'..."

	local owner_result
	local repo_result

	# shellcheck disable=SC2016
	owner_result=$(rg 'owner = "[^"]+"' "${ABS_NIX_FILE}" -o | sd 'owner = "([^"]+)"' '$1')
	# shellcheck disable=SC2016
	repo_result=$(rg 'repo = "[^"]+"' "${ABS_NIX_FILE}" -o | sd 'repo = "([^"]+)"' '$1')

	OWNER="${owner_result}"
	REPO="${repo_result}"

	if [[ -z "${OWNER}" ]] || [[ -z "${REPO}" ]]; then
		log_error "Could not extract owner/repo from '${ABS_NIX_FILE}'."
		log_error "Make sure the file contains 'owner' and 'repo' attributes."
		exit 1
	fi

	log_info "Found repository: ${OWNER}/${REPO}"
}

update_package() {
	trap cleanup EXIT

	log_info "Updating '${ABS_NIX_FILE}' for ${OWNER}/${REPO} with version '${VERSION}'..."

	# Create temporary wrapper using callPackage with proper path escaping
	cat >"${TEMP_WRAPPER}" <<EOF
{ pkgs ? import <nixpkgs> {} }:
rec {
  ${REPO} = pkgs.callPackage ${ABS_NIX_FILE} {};
}
EOF

	log_info "Executing nix-update..."
	printf "\n"

	# Use nix-update with temporary file
	if ! nix-update --version="${VERSION}" \
		-f ./"${TEMP_WRAPPER}" \
		--override-filename "${ABS_NIX_FILE}" \
		"${REPO}"; then
		log_error "nix-update failed"
		exit 1
	fi
}

#}}}

main "${@}"
