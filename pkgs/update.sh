#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq nix-update ripgrep sd
# shellcheck shell=bash

set -euo pipefail

cleanup() {
	if [ -f "temp-wrapper.nix" ]; then
		rm -f "temp-wrapper.nix"
	fi
}
trap cleanup EXIT

VERSION="branch"
NIX_FILE=""

show_help() {
	echo "Usage: [--version <version>] <nix-file>"
	echo ""
	echo "Options:"
	echo "  --help             Display this help and exit"
	echo "  --version <version> Specify version for nix-update (default: branch)"
	exit 0
}

if [ "$#" -eq 0 ]; then
	show_help
fi

# Parse command line arguments
while [ "$#" -gt 0 ]; do
	case "$1" in
	--help | -h)
		show_help
		;;
	--version)
		if [ "$#" -ge 2 ]; then
			VERSION="$2"
			shift 2
		else
			echo "Error: --version requires an argument"
			exit 1
		fi
		;;
	*)
		if [ -z "$NIX_FILE" ]; then
			NIX_FILE="$1"
			shift
		else
			echo "Error: Unexpected argument: $1"
			exit 1
		fi
		;;
	esac
done

if [ -z "$NIX_FILE" ]; then
	echo "Usage: $0 [--version <version>] <nix-file>"
	exit 1
fi

# Convert to absolute path
ABS_NIX_FILE=$(realpath "$NIX_FILE")

if [ ! -f "$ABS_NIX_FILE" ]; then
	echo "Error: File $NIX_FILE does not exist"
	exit 1
fi

# shellcheck disable=SC2016
# Extract owner and repo from the Nix file
OWNER=$(rg 'owner = "[^"]+"' "$ABS_NIX_FILE" -o | sd 'owner = "([^"]+)"' '$1')
# shellcheck disable=SC2016
REPO=$(rg 'repo = "[^"]+"' "$ABS_NIX_FILE" -o | sd 'repo = "([^"]+)"' '$1')

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
	echo "Error: Could not extract owner/repo from $ABS_NIX_FILE"
	exit 1
fi

echo "Updating $ABS_NIX_FILE for $OWNER/$REPO with version $VERSION..."

# Create temporary wrapper using callPackage with proper path escaping
cat >temp-wrapper.nix <<EOF
{ pkgs ? import <nixpkgs> {} }:
rec {
  ${REPO} = pkgs.callPackage ${ABS_NIX_FILE} {};
}
EOF

# Use nix-update with temporary file
nix-update --version="$VERSION" \
	-f ./temp-wrapper.nix \
	--override-filename "$ABS_NIX_FILE" \
	"${REPO}"
