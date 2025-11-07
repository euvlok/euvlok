#!/usr/bin/env bash
# Usage: ./nvidia-hashes.sh 560.35.03
#        (pass the driver version you want)

# Yeah I know I didn't do this the proper nix way with #!/usr/bin/env nix-shell but I can't be bothered to fix it rn.
echo "Uncomment sha256_aarch64 when the package releases"

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <driver-version>"
  echo "Example: $0 580.105.08"
  exit 1
fi

sri() {
  nix-hash --flat --base32 --type sha256 --sri $1
}

gh() {
  nix store prefetch-file --unpack --name source --json https://github.com/NVIDIA/$1/archive/$VERSION.tar.gz | jq -r .hash
}

DRIVER="NVIDIA-Linux-x86_64-$VERSION.run"
DRIVER_URL="https://download.nvidia.com/XFree86/Linux-x86_64/$VERSION"
AARCH64_DRIVER="NVIDIA-Linux-aarch64-$VERSION.run"
AARCH64_URL="https://download.nvidia.com/XFree86/aarch64/$VERSION"
echo "Fetching x86_64 driver $VERSION ..."
curl -flO "$DRIVER_URL/$DRIVER"
sha256=$(sri "$DRIVER")
echo "Fetching aarch64 driver"
#curl -fl0 "$AARCH64_URL/$AARCH64_DRIVER"
#sha256_aarch64=$(sri $AARCH64_DRIVER)
echo "Fetching NVIDIA open kernel modules"
openSha256=$(gh "open-gpu-kernel-modules")
echo "Fetching nvidia-settings"
settingsSha256=$(gh "nvidia-settings")
echo "Fetching nvidia-persistenced"
persistencedSha256=$(gh "nvidia-persistenced")

#cleanup
rm $DRIVER $AARCH64_DRIVER

echo "sha256 = \"$sha256\";"
#echo "sha256_aarch64 = \"$sha256_aarch64\";"
echo "openSha256 = \"$openSha256\";"
echo "settingsSha256 = \"$settingsSha256\";"
echo "persistencedSha256 = \"$persistencedSha256\";"
