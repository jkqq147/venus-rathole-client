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
    attempt=1
    while [ "$attempt" -le 3 ]; do
        if command -v wget >/dev/null 2>&1; then
            wget -q -T 45 -t 1 -O "$destination" "$url" && return 0
        elif command -v curl >/dev/null 2>&1; then
            curl -fsSL --connect-timeout 30 -o "$destination" "$url" && return 0
        else
            die "wget or curl is required"
        fi
        rm -f "$destination"
        [ "$attempt" -eq 3 ] || { printf '%s\n' "Download failed; retrying ($attempt/3)..." >&2; sleep 5; }
        attempt=$((attempt + 1))
    done
    die "could not download $url"
}

trap cleanup EXIT INT TERM
mkdir -p "$WORKDIR"
download "https://codeload.github.com/$REPOSITORY/zip/refs/heads/$REF" "$ARCHIVE"

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
