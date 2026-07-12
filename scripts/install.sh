#!/bin/sh
set -eu

RATHOLE_VERSION="${RATHOLE_VERSION:-v0.5.0}"
BASE_DIR="${VENUS_RATHOLE_BASE_DIR:-/data/venus-rathole}"
RC_LOCAL="${VENUS_RATHOLE_RC_LOCAL:-/data/rc.local}"
SERVICE_ROOT="${VENUS_RATHOLE_SERVICE_ROOT:-/service}"
SERVICE_NAME="venus-rathole"
MARKER_BEGIN="# BEGIN venus-rathole"
MARKER_END="# END venus-rathole"
CONFIGURE_AFTER_INSTALL=1

die() {
    printf '%s\n' "Error: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: install.sh [--no-configure]

Installs the Venus OS rathole client. --no-configure installs the service
without asking for server details.
EOF
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

verify_sha256() {
    file="$1"
    expected="$2"
    if command -v sha256sum >/dev/null 2>&1; then
        actual=$(sha256sum "$file" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        actual=$(shasum -a 256 "$file" | awk '{print $1}')
    else
        die "sha256sum or shasum is required"
    fi

    [ "$actual" = "$expected" ] || die "rathole download checksum did not match"
}

install_boot_hook() {
    mkdir -p "$(dirname "$RC_LOCAL")"
    if [ ! -f "$RC_LOCAL" ]; then
        printf '%s\n' '#!/bin/sh' > "$RC_LOCAL"
    fi

    cleaned="$RC_LOCAL.venus-rathole.cleaned.$$"
    block="$RC_LOCAL.venus-rathole.block.$$"
    output="$RC_LOCAL.venus-rathole.output.$$"
    sed "/^$MARKER_BEGIN$/,/^$MARKER_END$/d" "$RC_LOCAL" > "$cleaned"
    cat > "$block" <<EOF
$MARKER_BEGIN
"$BASE_DIR/scripts/start-service.sh" >/dev/null 2>&1 &
$MARKER_END
EOF

    first_line=$(sed -n '1p' "$cleaned")
    if [ "$first_line" = '#!/bin/sh' ]; then
        {
            sed -n '1p' "$cleaned"
            cat "$block"
            sed -n '2,$p' "$cleaned"
        } > "$output"
    else
        {
            printf '%s\n' '#!/bin/sh'
            cat "$block"
            cat "$cleaned"
        } > "$output"
    fi

    mv "$output" "$RC_LOCAL"
    chmod +x "$RC_LOCAL"
    rm -f "$cleaned" "$block"
}

case "${1:-}" in
    "") ;;
    --no-configure) CONFIGURE_AFTER_INSTALL=0 ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
esac

case "$BASE_DIR" in
    /data/*) [ -d /data ] || die "this installer must run on Venus OS, where /data is persistent" ;;
esac
command -v unzip >/dev/null 2>&1 || die "unzip is required"

case "$(uname -m)" in
    armv7l|armv7*)
        asset="rathole-armv7-unknown-linux-musleabihf.zip"
        checksum="e8662d80d2cc9acc5f8f4d8a1c1a5ff7717b2fa71919a405d0eed8b64c8c1d88"
        ;;
    aarch64|arm64)
        asset="rathole-aarch64-unknown-linux-musl.zip"
        checksum="fa4a6fc63d86f8f1faa7c103a845e4715ce79a048455c0eec897b27237576564"
        ;;
    *) die "unsupported Venus OS architecture: $(uname -m)" ;;
esac

temporary="${TMPDIR:-/tmp}/rathole-$SERVICE_NAME-$$.zip"
trap 'rm -f "$temporary"' EXIT INT TERM
mkdir -p "$BASE_DIR/bin" "$BASE_DIR/scripts" "$BASE_DIR/service"

download "https://github.com/rathole-org/rathole/releases/download/$RATHOLE_VERSION/$asset" "$temporary"
verify_sha256 "$temporary" "$checksum"
unzip -p "$temporary" rathole > "$BASE_DIR/bin/rathole"
chmod 700 "$BASE_DIR/bin/rathole"

unset CDPATH
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cp "$SCRIPT_DIR/configure.sh" "$BASE_DIR/scripts/configure.sh"
cp "$SCRIPT_DIR/start-service.sh" "$BASE_DIR/scripts/start-service.sh"
cp "$SCRIPT_DIR/uninstall.sh" "$BASE_DIR/scripts/uninstall.sh"
chmod 700 "$BASE_DIR/scripts/configure.sh" "$BASE_DIR/scripts/start-service.sh" "$BASE_DIR/scripts/uninstall.sh"
cat > "$BASE_DIR/service/run" <<EOF
#!/bin/sh
if [ ! -s "$BASE_DIR/client.toml" ]; then
    exec sleep 3600
fi
exec "$BASE_DIR/bin/rathole" --client "$BASE_DIR/client.toml" >/dev/null 2>&1
EOF
chmod 700 "$BASE_DIR/service/run"
cat > "$BASE_DIR/venus-rathole" <<EOF
#!/bin/sh
set -eu
case "\${1:-status}" in
    status) svstat "$SERVICE_ROOT/$SERVICE_NAME" ;;
    start) sv up "$SERVICE_ROOT/$SERVICE_NAME" ;;
    stop) sv down "$SERVICE_ROOT/$SERVICE_NAME" ;;
    restart) sv restart "$SERVICE_ROOT/$SERVICE_NAME" ;;
    configure) exec "$BASE_DIR/scripts/configure.sh" ;;
    uninstall) exec "$BASE_DIR/scripts/uninstall.sh" ;;
    *)
        printf '%s\\n' "Usage: venus-rathole {status|start|stop|restart|configure|uninstall}" >&2
        exit 1
        ;;
esac
EOF
chmod 700 "$BASE_DIR/venus-rathole"

install_boot_hook
"$BASE_DIR/scripts/start-service.sh"
if [ -s "$BASE_DIR/client.toml" ] && command -v sv >/dev/null 2>&1; then
    sv restart "$SERVICE_ROOT/$SERVICE_NAME" >/dev/null 2>&1 || true
fi

printf '%s\n' "Installed rathole $RATHOLE_VERSION in $BASE_DIR."
if [ "$CONFIGURE_AFTER_INSTALL" -eq 1 ]; then
    "$BASE_DIR/scripts/configure.sh"
else
    printf '%s\n' "Configure it with: $BASE_DIR/venus-rathole configure"
fi
