#!/bin/sh
# shellcheck source=scripts/rathole-release.sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)
. "$SCRIPT_DIR/rathole-release.sh"

PROJECT_VERSION=$(cat "$REPO_DIR/VERSION")
case "$PROJECT_VERSION" in
    v[0-9]*) ;;
    *) echo "VERSION must use vMAJOR.MINOR.PATCH format" >&2; exit 1 ;;
esac

ARCH="${1:-}"
[ -n "$ARCH" ] || { echo "Usage: package-offline.sh {armv7|aarch64} [output-dir]" >&2; exit 1; }
OUTPUT_DIR="${2:-$REPO_DIR/dist}"
select_rathole_release "$ARCH" || { echo "Unsupported architecture: $ARCH" >&2; exit 1; }

verify_sha256() {
    actual=$(shasum -a 256 "$1" | awk '{print $1}')
    [ "$actual" = "$2" ] || { echo "Checksum mismatch: $1" >&2; exit 1; }
}

PACKAGE_NAME="venus-rathole-client-${PROJECT_VERSION}-${ARCH}"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT INT TERM
STAGE="$WORKDIR/$PACKAGE_NAME"
mkdir -p "$STAGE/scripts" "$STAGE/gui" "$STAGE/service" "$OUTPUT_DIR"

curl -fsSL -o "$STAGE/$RATHOLE_ASSET" "https://github.com/rathole-org/rathole/releases/download/$RATHOLE_VERSION/$RATHOLE_ASSET"
verify_sha256 "$STAGE/$RATHOLE_ASSET" "$RATHOLE_SHA256"
cp "$REPO_DIR/install.sh" "$REPO_DIR/LICENSE" "$REPO_DIR/README.md" "$REPO_DIR/README.zh-CN.md" "$REPO_DIR/VERSION" "$STAGE/"
cp "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/start-service.sh" "$SCRIPT_DIR/uninstall.sh" "$SCRIPT_DIR/rathole-release.sh" "$STAGE/scripts/"
cp -R "$REPO_DIR/gui/qml" "$STAGE/gui/"
cp "$REPO_DIR/service/rathole-manager.py" "$STAGE/service/"
cat > "$STAGE/offline-install.sh" <<EOF
#!/bin/sh
set -eu
DIR=\$(CDPATH='' cd -- "\$(dirname -- "\$0")" && pwd)
RATHOLE_ARCHIVE="\$DIR/$RATHOLE_ASSET" sh "\$DIR/scripts/install.sh"
EOF
chmod 755 "$STAGE/offline-install.sh"
tar -C "$WORKDIR" -czf "$OUTPUT_DIR/$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME"
shasum -a 256 "$OUTPUT_DIR/$PACKAGE_NAME.tar.gz" > "$OUTPUT_DIR/$PACKAGE_NAME.tar.gz.sha256"
printf '%s\n' "$OUTPUT_DIR/$PACKAGE_NAME.tar.gz"
