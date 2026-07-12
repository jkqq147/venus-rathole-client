#!/bin/sh
set -eu

REPOSITORY="jkqq147/venus-rathole-client"
REF="${VENUS_RATHOLE_REF:-master}"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR="$TMP_ROOT/venus-rathole-client-$$"
ARCHIVE="$WORKDIR/source.zip"

cleanup() {
    rm -rf "$WORKDIR"
}

die() {
    printf '%s\n' "Error: $*" >&2
    exit 1
}

download() {
    url="$1"
    destination="$2"

    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$destination" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$destination" "$url"
    else
        die "wget or curl is required"
    fi
}

trap cleanup EXIT INT TERM
mkdir -p "$WORKDIR"
download "https://github.com/$REPOSITORY/archive/refs/heads/$REF.zip" "$ARCHIVE"

command -v unzip >/dev/null 2>&1 || die "unzip is required"
unzip -q "$ARCHIVE" -d "$WORKDIR"

SOURCE_DIR=""
for candidate in "$WORKDIR"/*; do
    if [ -d "$candidate" ] && [ -f "$candidate/scripts/install.sh" ]; then
        SOURCE_DIR="$candidate"
        break
    fi
done

[ -n "$SOURCE_DIR" ] || die "downloaded repository did not contain scripts/install.sh"
sh "$SOURCE_DIR/scripts/install.sh" "$@"
