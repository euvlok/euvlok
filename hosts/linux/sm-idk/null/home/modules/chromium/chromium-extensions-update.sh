#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq curl wget unzip nix git p7zip sd ripgrep yq-go nixfmt-rfc-style gnugrep
# shellcheck shell=bash
#
# Author: FlameFlag
#
#/ Usage: SCRIPTNAME [OPTIONS]
#/
#/ Generates a Nix file for Chromium extensions from a TOML configuration file.
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message.
#/   -i, --input <input_file>
#/                Specify the input TOML file.
#/                (default: modules/hm/gui/chromium/extensions.toml)
#/   -o, --output <output_file>
#/                Specify the output Nix file.
#/                (default: modules/hm/gui/chromium/extensions.nix)
#/
#/ EXAMPLES
#/   # Generate extensions.nix from default input file
#/   SCRIPTNAME
#/
#/   # Use custom input and output files
#/   SCRIPTNAME -i custom_extensions.toml -o custom_extensions.nix

set -euo pipefail

#{{{ Constants

SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_NAME

IFS=$'\t\n'

#}}}

#{{{ Variables

INPUT_FILE=""
OUTPUT_FILE=""
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

cleanup() {
	if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
		rm -rf -- "${TEMP_DIR}"
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

get_default_input_file() {
	local repo_root
	repo_root=$(find_repo_root) || {
		log_error "Could not find repository root"
		return 1
	}
	echo "extensions.toml"
}

get_default_output_file() {
	local repo_root
	repo_root=$(find_repo_root) || {
		log_error "Could not find repository root"
		return 1
	}
	echo "extensions.nix"
}

escape_nix_string() {
	# shellcheck disable=SC1003
	# Escape special characters for Nix string literals: backslash (\), double quote ("), dollar sign ($)
	# These characters have special meaning in Nix strings and must be escaped to prevent syntax errors
	# Note: Single quotes in sd patterns are tool syntax, not bash string literals
	printf '%s' "${1}" | sd '\\' '\\\\' | sd '"' '\\"' | sd '\$' '\\$'
}

get_chromium_major_version() {
	# Get Chromium version from Nix and extract major version using lib.versions.major
	# Chrome Web Store API requires major version for CRX download URLs (e.g., "143" for v143.x.x)
	local chromium_version
	local major_version

	# Try to get chromium version from nixpkgs
	chromium_version=$(nix eval --impure --expr '
		with import <nixpkgs> {};
		lib.getVersion chromium
	' 2>/dev/null | tr -d '"' || echo "")

	if [[ -z "${chromium_version}" ]]; then
		log_warning "Could not query Chromium version from Nix, using fallback: 143.0.0.0"
		chromium_version="143.0.0.0"
	fi

	# Extract major version using Nix's lib.versions.major
	major_version=$(nix eval --impure --expr "
		with import <nixpkgs> {};
		lib.versions.major \"${chromium_version}\"
	" 2>/dev/null | tr -d '"' || echo "")

	if [[ -z "${major_version}" ]]; then
		# Fallback: extract first number from version string directly
		major_version=$(echo "${chromium_version}" | cut -d. -f1)
	fi

	if [[ -z "${major_version}" ]] || ! [[ "${major_version}" =~ ^[0-9]+$ ]]; then
		log_warning "Could not determine Chromium major version, using default: 143"
		major_version="143"
	fi

	echo "${major_version}"
}

fetch_chrome_store_url() {
	local extension_id="${1}"
	log_info "Processing Chrome Web Store ID: ${extension_id}" >&2

	# Get Chromium major version automatically
	local prodversion
	prodversion=$(get_chromium_major_version)
	log_info "  -> Using Chromium major version: ${prodversion}" >&2

	local x_param="id%3D${extension_id}%26installsource%3Dondemand%26uc"
	local url="https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=${prodversion}&x=${x_param}"
	curl -w "%{url_effective}" -I -L -sS "${url}" -o /dev/null 2>&1
}

fetch_bpc_url() {
	local extension_id="${1}"
	log_info "Processing special case 'bpc' for ID: ${extension_id}" >&2
	local bpc_repo="https://gitflic.ru/project/magnolia1234/bpc_uploads.git"
	local commit
	commit=$(git ls-remote "${bpc_repo}" HEAD | awk '{print $1}')
	if [[ -z "${commit}" ]]; then
		log_error "Failed to get latest commit for bypass-paywalls-chrome"
		return 1
	fi
	log_info "  -> Using BPC commit: ${commit}" >&2
	echo "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass-paywalls-chrome-clean-latest.crx&inline=false&commit=${commit}"
}

fetch_github_release_url() {
	local extension_id="${1}"
	local toml_file="${2}"
	local extension_index="${3}"

	log_info "Processing GitHub release for ID: ${extension_id}" >&2

	# Extract GitHub release configuration from TOML file
	# Extension-level fields override config-level defaults for flexibility
	local owner
	local repo
	local pattern
	local version

	# Try extension-level fields first, then fall back to config-level defaults
	owner=$(yq -oy -r ".extensions[${extension_index}].owner" "${toml_file}" 2>/dev/null)
	if [[ -z "${owner}" ]] || [[ "${owner}" == "null" ]]; then
		owner=$(yq -oy -r ".config.sources.\"github-releases\".owner" "${toml_file}" 2>/dev/null)
	fi

	repo=$(yq -oy -r ".extensions[${extension_index}].repo" "${toml_file}" 2>/dev/null)
	if [[ -z "${repo}" ]] || [[ "${repo}" == "null" ]]; then
		repo=$(yq -oy -r ".config.sources.\"github-releases\".repo" "${toml_file}" 2>/dev/null)
	fi

	pattern=$(yq -oy -r ".extensions[${extension_index}].pattern" "${toml_file}" 2>/dev/null)
	if [[ -z "${pattern}" ]] || [[ "${pattern}" == "null" ]]; then
		pattern=$(yq -oy -r ".config.sources.\"github-releases\".pattern" "${toml_file}" 2>/dev/null)
	fi

	version=$(yq -oy -r ".extensions[${extension_index}].version" "${toml_file}" 2>/dev/null)
	if [[ -z "${version}" ]] || [[ "${version}" == "null" ]]; then
		version="latest"
	fi

	if [[ -z "${owner}" ]] || [[ "${owner}" == "null" ]] || [[ -z "${repo}" ]] || [[ "${repo}" == "null" ]]; then
		log_error "GitHub release source requires 'owner' and 'repo' fields (extension or config level)"
		return 1
	fi

	# If version is specified and not "latest", use it; otherwise get latest release
	if [[ -n "${version}" ]] && [[ "${version}" != "null" ]] && [[ "${version}" != "latest" ]]; then
		log_info "  -> Using specified version: ${version}" >&2
		# Remove 'v' prefix if present
		version="${version#v}"
	else
		log_info "  -> Fetching latest release from ${owner}/${repo}..." >&2
		# Get latest release tag from GitHub API
		version=$(curl -sL "https://api.github.com/repos/${owner}/${repo}/releases/latest" | jq -r '.tag_name // .name // empty' 2>/dev/null)
		if [[ -z "${version}" ]] || [[ "${version}" == "null" ]]; then
			log_error "Failed to get latest release version from GitHub API"
			return 1
		fi
		# Remove 'v' prefix if present
		version="${version#v}"
		log_info "  -> Latest release version: ${version}" >&2
	fi

	# Build URL from pattern
	local finalurl
	if [[ -n "${pattern}" ]] && [[ "${pattern}" != "null" ]]; then
		# Replace placeholders in pattern: {version}, {name}, {id}
		local url_pattern="${pattern}"
		url_pattern="${url_pattern//\{version\}/${version}}"
		url_pattern="${url_pattern//\{name\}/${extension_id}}"
		url_pattern="${url_pattern//\{id\}/${extension_id}}"
		finalurl="https://github.com/${owner}/${repo}/${url_pattern}"
	else
		# Default pattern: releases/download/v{version}/{id}.crx
		finalurl="https://github.com/${owner}/${repo}/releases/download/v${version}/${extension_id}.crx"
	fi

	log_info "  -> GitHub release URL: ${finalurl}" >&2
	echo "${finalurl}"
}

process_extension() {
	local extension_index="${1}"
	local toml_file="${2}"
	local temp_dir="${3}"
	local output_file="${4}"

	# Extract extension fields from TOML using yq
	local id
	local source
	local url
	local condition
	local name
	local owner
	local repo
	local pattern
	local version

	id=$(yq -oy -r ".extensions[${extension_index}].id" "${toml_file}" 2>/dev/null)
	if [[ -z "${id}" ]] || [[ "${id}" == "null" ]]; then
		log_warning "Extension at index ${extension_index} missing 'id' field, skipping"
		return 0
	fi

	source=$(yq -oy -r ".extensions[${extension_index}].source" "${toml_file}" 2>/dev/null)
	if [[ -z "${source}" ]] || [[ "${source}" == "null" ]]; then
		source="chrome-store"
	fi

	url=$(yq -oy -r ".extensions[${extension_index}].url" "${toml_file}" 2>/dev/null)
	if [[ -z "${url}" ]] || [[ "${url}" == "null" ]]; then
		url=""
	fi

	condition=$(yq -oy -r ".extensions[${extension_index}].condition" "${toml_file}" 2>/dev/null)
	if [[ -z "${condition}" ]] || [[ "${condition}" == "null" ]]; then
		condition=""
	fi

	name=$(yq -oy -r ".extensions[${extension_index}].name" "${toml_file}" 2>/dev/null)
	if [[ -z "${name}" ]] || [[ "${name}" == "null" ]]; then
		name=""
	fi

	# Log extension name if available
	if [[ -n "${name}" ]] && [[ "${name}" != "null" ]]; then
		log_info "Processing: ${name} (${id})"
	else
		log_info "Processing extension: ${id}"
	fi

	local finalurl=""

	case "${source}" in
	chrome-store)
		finalurl=$(fetch_chrome_store_url "${id}") || return 1
		;;
	bpc)
		finalurl=$(fetch_bpc_url "${id}") || return 1
		;;
	url)
		if [[ -z "${url}" ]] || [[ "${url}" == "null" ]]; then
			log_error "Extension '${id}' has source 'url' but no 'url' field specified"
			return 1
		fi
		log_info "Using direct URL for ID: ${id}"
		finalurl="${url}"
		;;
	github-releases)
		finalurl=$(fetch_github_release_url "${id}" "${toml_file}" "${extension_index}") || return 1
		;;
	*)
		log_error "Unknown source '${source}' for extension '${id}'. Must be 'chrome-store', 'bpc', 'url', or 'github-releases'"
		return 1
		;;
	esac

	log_info "  -> Downloading from: ${finalurl}"
	local download_path="${temp_dir}/${id}.crx"
	if ! wget --quiet --output-document="${download_path}" "${finalurl}"; then
		log_error "Failed to download extension from ${finalurl}"
		return 1
	fi

	# Verify file was downloaded and is not empty
	if [[ ! -f "${download_path}" ]] || [[ ! -s "${download_path}" ]]; then
		log_error "Downloaded file is missing or empty"
		return 1
	fi

	local hex_hash
	hex_hash=$(sha256sum "${download_path}" | cut -d' ' -f1)
	local hash
	hash=$(nix hash to-sri --type sha256 "${hex_hash}")

	local unzip_dir="${temp_dir}/unzipped-${id}"
	mkdir -p "${unzip_dir}"

	# CRX files are ZIP archives with a special header containing metadata and signatures
	# CRX3 format: starts with "Cr24" (0x43 0x72 0x32 0x34) magic bytes, followed by version info
	# The actual ZIP data starts after the header. We find ZIP magic bytes "PK" to locate the archive
	local zip_path="${download_path}"

	# Check if it's CRX3 format (starts with Cr24) - if so, we need to skip the header
	# CRX3 headers contain version, public key, and signature data before the ZIP content
	local crx_header
	crx_header=$(head -c 4 "${download_path}" 2>/dev/null || echo "")

	# Check for CRX3 magic: "Cr24" (0x43 0x72 0x32 0x34)
	if [[ "${crx_header}" == "Cr24" ]]; then
		log_info "  -> Detected CRX3 format, finding ZIP offset..."
		# Find ZIP magic bytes "PK" (0x50 0x4B 0x03 0x04) which mark the start of ZIP content
		# CRX3 headers are variable-length, so we scan for the ZIP signature to find the exact offset
		# Prefer ripgrep for speed, fallback to grep for compatibility
		local zip_offset
		if command -v rg &>/dev/null; then
			# ripgrep -abo returns "offset:match", we need just the offset
			zip_offset=$(rg -abo "PK" "${download_path}" 2>/dev/null | head -1 | cut -d: -f1)
		else
			zip_offset=$(grep -abo "PK" "${download_path}" 2>/dev/null | head -1 | cut -d: -f1)
		fi

		if [[ -n "${zip_offset}" ]] && [[ "${zip_offset}" =~ ^[0-9]+$ ]] && [[ "${zip_offset}" -gt 0 ]]; then
			log_info "  -> Found ZIP at offset ${zip_offset}, extracting ZIP portion..."
			# Extract ZIP portion starting from PK. zip_offset is 0-based, but tail -c is 1-based
			# So we add 1 to get the correct starting position for tail
			zip_path="${temp_dir}/${id}.zip"
			if ! tail -c +$((zip_offset + 1)) "${download_path}" > "${zip_path}" 2>/dev/null; then
				log_error "Failed to extract ZIP portion from CRX file"
				return 1
			fi
			if [[ ! -f "${zip_path}" ]] || [[ ! -s "${zip_path}" ]]; then
				log_error "Extracted ZIP file is missing or empty"
				return 1
			fi
			log_info "  -> Successfully extracted ZIP portion (size: $(stat -f%z "${zip_path}" 2>/dev/null || stat -c%s "${zip_path}" 2>/dev/null || echo "unknown") bytes)"
		else
			log_warning "  -> CRX3 detected but could not find ZIP offset (found: '${zip_offset}'), trying direct extraction..."
		fi
	fi

	# Try unzip first - it can handle CRX files even with extra header bytes before ZIP content
	# unzip may warn about "extra bytes" but will extract successfully. Fallback to 7z if unzip fails
	# Verify success by checking for manifest.json, the required Chrome extension metadata file
	log_info "  -> Extracting archive with unzip..."
	local unzip_output
	unzip_output=$(unzip -q -o "${zip_path}" -d "${unzip_dir}" 2>&1)
	local unzip_exit=$?

	if [[ ${unzip_exit} -ne 0 ]] || [[ ! -f "${unzip_dir}/manifest.json" ]]; then
		log_info "  -> unzip failed (exit ${unzip_exit}), trying 7z..."
		# unzip failed, try 7z
		local p7zip_output
		p7zip_output=$(7z x -o"${unzip_dir}" "${zip_path}" 2>&1)
		local p7zip_exit=$?

		if [[ ${p7zip_exit} -ne 0 ]] || [[ ! -f "${unzip_dir}/manifest.json" ]]; then
			log_error "Failed to extract archive for '${id}'"
			log_error "unzip exit code: ${unzip_exit}, 7z exit code: ${p7zip_exit}"
			if [[ -n "${unzip_output}" ]]; then
				log_error "unzip output: ${unzip_output}"
			fi
			if [[ -n "${p7zip_output}" ]]; then
				log_error "7z output: ${p7zip_output}"
			fi
			return 1
		fi
	fi

	local manifest_path="${unzip_dir}/manifest.json"
	if [[ ! -f "${manifest_path}" ]]; then
		log_error "manifest.json not found for '${id}' - invalid extension archive"
		return 1
	fi

	# Extract version from Chrome extension manifest (required field for Nix)
	local version
	version=$(jq -r ".version" < "${manifest_path}")
	if [[ "${version}" == "null" ]]; then
		# Some extensions use version_name instead of version
		version=$(jq -r ".version_name" < "${manifest_path}")
	fi
	if [[ "${version}" == "null" ]]; then
		log_error "Could not extract version from manifest for '${id}'"
		return 1
	fi

	rm -r "${unzip_dir}"

	# Escape values for safe insertion into Nix file
	local id_escaped
	local finalurl_escaped
	local hash_escaped
	local version_escaped
	local condition_escaped
	id_escaped=$(escape_nix_string "${id}")
	finalurl_escaped=$(escape_nix_string "${finalurl}")
	hash_escaped=$(escape_nix_string "${hash}")
	version_escaped=$(escape_nix_string "${version}")

	if [[ -n "${condition}" ]] && [[ "${condition}" != "null" ]]; then
		condition_escaped=$(escape_nix_string "${condition}")
		log_info "  -> Generating conditional entry with condition: ${condition}"
		cat >> "${output_file}" <<EOF
  (lib.optionals (${condition_escaped}) [
    {
      id = "${id_escaped}";
      crxPath = pkgs.fetchurl {
        url = "${finalurl_escaped}";
        name = "${id_escaped}.crx";
        hash = "${hash_escaped}";
      };
      version = "${version_escaped}";
    }
  ])
EOF
	else
		cat >> "${output_file}" <<EOF
  {
    id = "${id_escaped}";
    crxPath = pkgs.fetchurl {
      url = "${finalurl_escaped}";
      name = "${id_escaped}.crx";
      hash = "${hash_escaped}";
    };
    version = "${version_escaped}";
  }
EOF
	fi
}

parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case "${1}" in
		-h | --help)
			show_help
			exit 0
			;;
		-i | --input)
			if [[ -z "${2-}" ]]; then
				log_error "--input requires a value"
				show_help
				exit 1
			fi
			INPUT_FILE="${2}"
			shift 2
			;;
		-o | --output)
			if [[ -z "${2-}" ]]; then
				log_error "--output requires a value"
				show_help
				exit 1
			fi
			OUTPUT_FILE="${2}"
			shift 2
			;;
		-*)
			log_error "Unknown option: ${1}"
			show_help
			exit 1
			;;
		*)
			log_error "Unexpected argument: '${1}'"
			show_help
			exit 1
			;;
		esac
	done
}

#}}}

main() {
	parse_arguments "${@}"

	# Set default values if not provided
	if [[ -z "${INPUT_FILE}" ]]; then
		INPUT_FILE=$(get_default_input_file) || exit 1
	fi
	if [[ -z "${OUTPUT_FILE}" ]]; then
		OUTPUT_FILE=$(get_default_output_file) || exit 1
	fi

	readonly INPUT_FILE
	readonly OUTPUT_FILE

	if [[ ! -f "${INPUT_FILE}" ]]; then
		log_error "Input file not found at '${INPUT_FILE}'"
		exit 1
	fi

	# Validate TOML file syntax (yq-go auto-detects TOML from .toml extension, output as YAML)
	if ! yq -oy '.' "${INPUT_FILE}" >/dev/null 2>&1; then
		log_error "Invalid TOML file: ${INPUT_FILE}"
		exit 1
	fi

	log_info "Generating ${OUTPUT_FILE} from ${INPUT_FILE}..."

	TEMP_DIR=$(mktemp -d)
	readonly TEMP_DIR
	trap cleanup EXIT

	local tmp_output_file="${TEMP_DIR}/extensions.nix.tmp"

	# Get the number of extensions in the TOML file
	local extension_count
	extension_count=$(yq -oy '.extensions | length' "${INPUT_FILE}" 2>/dev/null)

	# Check if any extension has a condition
	local has_conditions=false
	if [[ -n "${extension_count}" ]] && [[ "${extension_count}" != "0" ]]; then
		for ((i = 0; i < extension_count; i++)); do
			local condition
			condition=$(yq -oy -r ".extensions[${i}].condition" "${INPUT_FILE}" 2>/dev/null)
			if [[ -n "${condition}" ]] && [[ "${condition}" != "null" ]] && [[ "${condition}" != "" ]]; then
				has_conditions=true
				break
			fi
		done
	fi

	# Generate header with or without config based on whether conditions exist
	if [[ "${has_conditions}" == "true" ]]; then
		cat > "${tmp_output_file}" <<EOF
# This file is auto-generated by an update script
# DO NOT edit manually
{
  pkgs,
  config,
  lib,
  ...
}:
lib.flatten [
EOF
	else
		cat > "${tmp_output_file}" <<EOF
# This file is auto-generated by an update script
# DO NOT edit manually
{
  pkgs,
  lib,
  ...
}:
lib.flatten [
EOF
	fi

	if [[ -z "${extension_count}" ]] || [[ "${extension_count}" == "0" ]]; then
		log_warning "No extensions found in ${INPUT_FILE}"
	else
		log_info "Found ${extension_count} extension(s) to process"
		for ((i = 0; i < extension_count; i++)); do
			process_extension "${i}" "${INPUT_FILE}" "${TEMP_DIR}" "${tmp_output_file}" || {
				log_error "Failed to process extension at index ${i}"
				exit 1
			}
		done
	fi

	echo "]" >> "${tmp_output_file}"

	# Format the generated file with nixfmt-rfc-style
	log_info "Formatting generated Nix file with nixfmt-rfc-style..."
	if ! nixfmt-rfc-style "${tmp_output_file}" 2>/dev/null; then
		log_warning "nixfmt-rfc-style failed or produced warnings, continuing anyway"
	fi

	# Validate syntax before replacing original file
	if ! nix-instantiate --parse "${tmp_output_file}" >/dev/null 2>&1; then
		log_error "Generated nix file is invalid"
		exit 1
	fi

	mv "${tmp_output_file}" "${OUTPUT_FILE}"
	log_success "Successfully generated and replaced ${OUTPUT_FILE}!"
}

#}}}

main "${@}"
