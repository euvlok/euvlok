#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq curl nix sd ripgrep fd
# shellcheck shell=bash
#
# Author: FlameFlag
#
#/ Usage: SCRIPTNAME [OPTIONS] [driver-version]
#/
#/ Fetch and compute SHA256 hashes for NVIDIA driver packages and related repositories.
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message.
#/   -v, --version <version>
#/                Specify a particular NVIDIA driver version to fetch.
#/   -l, --latest
#/                Fetch the latest available NVIDIA driver version (default if no version specified).
#/   -u, --update
#/                Automatically update modules/nixos/nvidia-driver.nix with the fetched hashes (default).
#/   --no-update
#/                Do not update the nvidia-driver.nix file, only print the hashes.
#/
#/ ARGUMENTS
#/   [driver-version]
#/                Optional positional argument for driver version (e.g., 580.105.08).
#/                If not provided and --latest is not specified, defaults to latest.
#/
#/ EXAMPLES
#/   # Fetch hashes for the latest driver version and update nvidia-driver.nix
#/   SCRIPTNAME --latest
#/
#/   # Fetch hashes for a specific driver version using flag and update nvidia-driver.nix
#/   SCRIPTNAME --version 580.105.08
#/
#/   # Fetch hashes for a specific driver version using positional argument
#/   SCRIPTNAME 580.105.08
#/
#/   # Fetch latest but only print hashes without updating the file
#/   SCRIPTNAME --latest --no-update
#/
#/ NOTE
#/   When fetching the latest version, the script checks both x86_64 and aarch64
#/   platforms and returns the latest version available on both.

set -euo pipefail

#{{{ Constants

SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_NAME
readonly X86_64_BASE_URL="https://download.nvidia.com/XFree86/Linux-x86_64"
readonly AARCH64_BASE_URL="https://download.nvidia.com/XFree86/Linux-aarch64"
readonly GITHUB_BASE_URL="https://github.com/NVIDIA"

IFS=$'\t\n'

#}}}

#{{{ Variables

VERSION=""
FETCH_LATEST=false
UPDATE_FILE=true
TEMP_DIR=""

#}}}

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
	rg '^#/' "${BASH_SOURCE[0]}" | cut -c4- | sd "SCRIPTNAME" "${SCRIPT_NAME}"
}

fetch_versions_from_platform() {
	local platform_url="${1}"
	local platform_name="${2}"

	log_info "Checking ${platform_name} platform..." >&2

	local versions
	versions=$(
		curl -sL "${platform_url}/" |
			rg -o "href='[0-9]+\.[0-9]+\.[0-9]+/" |
			sd "href='" '' |
			sd "/'" '' |
			sd '/$' '' |
			sort -V
	)

	if [[ -z "${versions}" ]]; then
		log_error "Could not fetch versions from ${platform_name} platform" >&2
		return 1
	fi

	echo "${versions}"
}

find_common_latest_version() {
	local versions1="${1}"
	local versions2="${2}"

	# Find intersection of both version lists and return the latest
	# uniq -d finds duplicates (common versions), tail -1 gets the latest
	local common_version
	common_version=$(
		printf '%s\n' "${versions1}" "${versions2}" |
			sort -V |
			uniq -d |
			tail -1
	)

	if [[ -z "${common_version}" ]]; then
		return 1
	fi

	echo "${common_version}"
}

fetch_latest_version() {
	log_info "Fetching latest NVIDIA driver version from all platforms..." >&2

	local x86_64_versions
	local aarch64_versions

	x86_64_versions=$(fetch_versions_from_platform "${X86_64_BASE_URL}" "x86_64") || return 1
	aarch64_versions=$(fetch_versions_from_platform "${AARCH64_BASE_URL}" "aarch64") || return 1

	local latest_version
	latest_version=$(find_common_latest_version "${x86_64_versions}" "${aarch64_versions}") || {
		log_error "Could not find a version available on both platforms" >&2
		log_error "Please specify a version manually using --version flag" >&2
		return 1
	}

	if [[ -z "${latest_version}" ]]; then
		log_error "Could not find a version available on both platforms" >&2
		log_error "Please specify a version manually using --version flag" >&2
		return 1
	fi

	echo "${latest_version}"
}

sri() {
	nix-hash --flat --base32 --type sha256 --sri "${1}"
}

escape_nix_string() {
	# shellcheck disable=SC1003
	# Escape special characters for Nix string literals: backslash, double quote, dollar sign
	# Single quotes in sd patterns are tool syntax, not bash string literals
	printf '%s' "${1}" | sd '\\' '\\\\' | sd '"' '\\"' | sd '\$' '\\$'
}

fetch_driver_hash() {
	local arch="${1}"
	local base_url="${2}"
	local version="${3}"
	local temp_dir="${4}"
	local driver_name="NVIDIA-Linux-${arch}-${version}.run"
	local driver_url="${base_url}/${version}/${driver_name}"
	local driver_path="${temp_dir}/${driver_name}"

	log_info "Fetching ${arch} driver ${version}..." >&2
	curl -fL "${driver_url}" -o "${driver_path}" >&2
	sri "${driver_path}"
}

fetch_github_hash() {
	local repo="${1}"
	local url="${GITHUB_BASE_URL}/${repo}/archive/${VERSION}.tar.gz"

	nix store prefetch-file --unpack --name source --json "${url}" | jq -r .hash
}

cleanup() {
	if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
		rm -rf "${TEMP_DIR}"
		log_info "Cleaned up temporary directory"
	fi
}

find_repo_root() {
	local script_dir
	script_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

	local current_dir="${script_dir}"
	while [[ "${current_dir}" != "/" ]]; do
		if [[ -f "${current_dir}/flake.nix" ]] || [[ -d "${current_dir}/.git" ]]; then
			echo "${current_dir}"
			return 0
		fi
		current_dir=$(dirname "${current_dir}")
	done

	return 1
}

find_nvidia_driver_nix() {
	local repo_root
	repo_root=$(find_repo_root) || {
		return 1
	}

	local nvidia_driver_nix
	nvidia_driver_nix=$(
		fd \
			--type f \
			--search-path "${repo_root}" \
			--glob "**/nvidia-driver.nix" |
			head -1
	)

	if [[ -n "${nvidia_driver_nix}" ]] && [[ -f "${nvidia_driver_nix}" ]]; then
		echo "${nvidia_driver_nix}"
		return 0
	fi

	return 1
}

update_nvidia_driver_nix() {
	local version="${1}"
	local sha256_64bit="${2}"
	local sha256_aarch64="${3}"
	local openSha256="${4}"
	local settingsSha256="${5}"
	local persistencedSha256="${6}"

	local nvidia_driver_nix_file
	nvidia_driver_nix_file=$(find_nvidia_driver_nix) || {
		log_error "Could not find modules/nixos/nvidia-driver.nix file"
		log_error "Make sure you're running this script from within the repository"
		return 1
	}

	if [[ -z "${nvidia_driver_nix_file}" ]]; then
		log_error "Could not find modules/nixos/nvidia-driver.nix file"
		log_error "Make sure you're running this script from within the repository"
		return 1
	fi

	log_info "Updating ${nvidia_driver_nix_file}..."

	# Create backup
	local backup_file
	backup_file="${nvidia_driver_nix_file}.backup"
	if ! cp "${nvidia_driver_nix_file}" "${backup_file}"; then
		log_error "Failed to create backup of ${nvidia_driver_nix_file}"
		return 1
	fi
	log_info "Created backup: ${backup_file}"

	# Escape all values for safe insertion into Nix file
	local version_escaped
	local sha256_64bit_escaped
	local sha256_aarch64_escaped
	local openSha256_escaped
	local settingsSha256_escaped
	local persistencedSha256_escaped

	version_escaped=$(escape_nix_string "${version}")
	sha256_64bit_escaped=$(escape_nix_string "${sha256_64bit}")
	sha256_aarch64_escaped=$(escape_nix_string "${sha256_aarch64}")
	openSha256_escaped=$(escape_nix_string "${openSha256}")
	settingsSha256_escaped=$(escape_nix_string "${settingsSha256}")
	persistencedSha256_escaped=$(escape_nix_string "${persistencedSha256}")

	local temp_file
	temp_file=$(mktemp)
	cat >"${temp_file}" <<EOF
{
  version = "${version_escaped}";
  sha256_64bit = "${sha256_64bit_escaped}";
  sha256_aarch64 = "${sha256_aarch64_escaped}";
  openSha256 = "${openSha256_escaped}";
  settingsSha256 = "${settingsSha256_escaped}";
  persistencedSha256 = "${persistencedSha256_escaped}";
}
EOF

	# Validate syntax before replacing original file
	# If invalid, restore backup to prevent corruption
	if ! nix-instantiate --parse "${temp_file}" >/dev/null 2>&1; then
		log_error "Generated nix file is invalid, restoring backup"
		mv "${backup_file}" "${nvidia_driver_nix_file}"
		rm -f "${temp_file}"
		return 1
	fi

	mv "${temp_file}" "${nvidia_driver_nix_file}"
	rm -f "${backup_file}"

	log_success "Successfully updated ${nvidia_driver_nix_file}"
}

parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case "${1}" in
		-h | --help)
			show_help
			exit 0
			;;
		-v | --version)
			# ${2-} provides empty string if $2 is unset, avoiding unbound variable error
			if [[ -z "${2-}" ]]; then
				log_error "--version requires a value"
				show_help
				exit 1
			fi
			VERSION="${2}"
			shift 2
			;;
		-l | --latest)
			FETCH_LATEST=true
			shift
			;;
		-u | --update)
			UPDATE_FILE=true
			shift
			;;
		--no-update)
			UPDATE_FILE=false
			shift
			;;
		-*)
			log_error "Unknown option: ${1}"
			show_help
			exit 1
			;;
		*)
			if [[ -z "${VERSION}" ]]; then
				VERSION="${1}"
			else
				log_error "Unexpected argument: '${1}', a version has already been provided"
				show_help
				exit 1
			fi
			shift
			;;
		esac
	done
}

#}}}

main() {
	parse_arguments "${@}"

	if [[ -n "${VERSION}" ]] && [[ "${FETCH_LATEST}" == true ]]; then
		log_error "Cannot specify both --version and --latest"
		show_help
		exit 1
	fi

	if [[ -z "${VERSION}" ]]; then
		local fetched_version
		fetched_version=$(fetch_latest_version) || exit 1

		if [[ -z "${fetched_version}" ]]; then
			log_error "Failed to determine latest version"
			exit 1
		fi

		VERSION="${fetched_version}"
		log_success "Using latest driver version: ${VERSION}"
	fi

	readonly VERSION

	TEMP_DIR=$(mktemp -d)
	readonly TEMP_DIR
	trap cleanup EXIT

	log_info "Fetching hashes for NVIDIA driver version ${VERSION}..."

	local sha256
	sha256=$(fetch_driver_hash "x86_64" "${X86_64_BASE_URL}" "${VERSION}" "${TEMP_DIR}")

	local sha256_aarch64
	sha256_aarch64=$(fetch_driver_hash "aarch64" "${AARCH64_BASE_URL}" "${VERSION}" "${TEMP_DIR}")

	log_info "Fetching NVIDIA open kernel modules..."
	local openSha256
	openSha256=$(fetch_github_hash "open-gpu-kernel-modules")

	log_info "Fetching nvidia-settings..."
	local settingsSha256
	settingsSha256=$(fetch_github_hash "nvidia-settings")

	log_info "Fetching nvidia-persistenced..."
	local persistencedSha256
	persistencedSha256=$(fetch_github_hash "nvidia-persistenced")

	printf "\n"
	log_success "Hash computation completed!"
	printf "\n"

	echo "sha256 = \"${sha256}\";"
	echo "sha256_aarch64 = \"${sha256_aarch64}\";"
	echo "openSha256 = \"${openSha256}\";"
	echo "settingsSha256 = \"${settingsSha256}\";"
	echo "persistencedSha256 = \"${persistencedSha256}\";"

	if [[ "${UPDATE_FILE}" == true ]]; then
		printf "\n"
		if ! update_nvidia_driver_nix \
			"${VERSION}" \
			"${sha256}" \
			"${sha256_aarch64}" \
			"${openSha256}" \
			"${settingsSha256}" \
			"${persistencedSha256}"; then
			log_error "Failed to update nvidia-driver.nix file"
			exit 1
		fi
	fi
}

#}}}

main "${@}"
