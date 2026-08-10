#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY_DIR="$REPO_DIR/files"
PACKAGES_FILE="$REPO_DIR/build/packages.txt"
OUTPUT_DIR="$REPO_DIR/output"
PROFILE="linksys_e8450-ubi"
TARGET="mediatek"
SUBTARGET="mt7622"

VERSION="${1:-}"
OPENWRT_VERSION="${2:-24.10.5}"

if [[ -z "$VERSION" ]]; then
  read -r -p "Enter custom image version (e.g. 1.6.1): " VERSION
fi
[[ -n "$VERSION" ]] || { echo "ERROR: image version cannot be empty." >&2; exit 1; }

BUILD_DATE="$(date '+%Y-%m-%d %H:%M')"
BUILD_FILENAME_DATE="$(date '+%Y-%m-%d_%H-%M-%S')"
IMAGE_NAME="invio_v${VERSION}_${BUILD_FILENAME_DATE}"
ARCHIVE="openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.zst"
BASE_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}"
WORK_ROOT="${TMPDIR:-/tmp}/invio-openwrt-build"
IMAGEBUILDER_DIR="$WORK_ROOT/${ARCHIVE%.tar.zst}"

for cmd in wget tar sha256sum awk grep sed make; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: missing required command: $cmd" >&2; exit 1; }
done

rm -rf "$WORK_ROOT"
mkdir -p "$WORK_ROOT" "$OUTPUT_DIR"
cd "$WORK_ROOT"

echo "Downloading OpenWrt ImageBuilder ${OPENWRT_VERSION}..."
wget -q --show-progress "$BASE_URL/$ARCHIVE"
wget -q "$BASE_URL/sha256sums"
grep "  ${ARCHIVE}$" sha256sums | sha256sum -c -

tar --zstd -xf "$ARCHIVE"
cp -a "$OVERLAY_DIR" "$IMAGEBUILDER_DIR/files"

BANNER_TEMPLATE="$IMAGEBUILDER_DIR/files/etc/banner.template"
BANNER_FILE="$IMAGEBUILDER_DIR/files/etc/banner"
cp "$BANNER_TEMPLATE" "$BANNER_FILE"

update_banner_field() {
  local file="$1" placeholder="$2" value="$3"
  awk -v placeholder="$placeholder" -v value="$value" '
  {
    if (index($0, placeholder)) {
      original_length=length($0); sub(placeholder,value); difference=original_length-length($0)
      if ($0 !~ /║$/) { print "ERROR: banner field line has no closing border" > "/dev/stderr"; exit 1 }
      sub(/║$/,"")
      if (difference>0) for(i=0;i<difference;i++) $0=$0 " "
      else if (difference<0) for(i=0;i<-difference;i++) {
        if ($0 ~ / $/) sub(/ $/,""); else { print "ERROR: banner value too long" > "/dev/stderr"; exit 1 }
      }
      $0=$0 "║"
      if(length($0)!=original_length) exit 1
    }
    print
  }' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

update_banner_field "$BANNER_FILE" "__VERSION__" "$VERSION"
update_banner_field "$BANNER_FILE" "__OPENWRT_VERSION__" "$OPENWRT_VERSION"
update_banner_field "$BANNER_FILE" "__BUILD_DATE__" "$BUILD_DATE"

find "$IMAGEBUILDER_DIR/files/usr/bin" "$IMAGEBUILDER_DIR/files/usr/sbin" -type f -exec chmod 0755 {} +
chmod 0755 "$IMAGEBUILDER_DIR/files/etc/hotplug.d/block/99-usb-alias" \
           "$IMAGEBUILDER_DIR/files/etc/init.d/dhcp-reclaim" \
           "$IMAGEBUILDER_DIR/files/etc/uci-defaults/20-create-ftp-admin" \
           "$IMAGEBUILDER_DIR/files/etc/uci-defaults/95-enable-dhcp-reclaim"

PACKAGES="$(grep -vE '^\s*(#|$)' "$PACKAGES_FILE" | tr '\n' ' ')"

echo "Building $IMAGE_NAME for profile $PROFILE..."
cd "$IMAGEBUILDER_DIR"
make image PROFILE="$PROFILE" PACKAGES="$PACKAGES" FILES="files" EXTRA_IMAGE_NAME="$IMAGE_NAME"

find bin/targets -type f \( -name '*.itb' -o -name '*.bin' -o -name '*.img.gz' \) -exec cp -v {} "$OUTPUT_DIR/" \;
echo "Build complete. Output: $OUTPUT_DIR"
