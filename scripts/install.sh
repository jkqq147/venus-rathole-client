#!/bin/sh
# shellcheck source=scripts/rathole-release.sh
set -eu

BASE_DIR="${VENUS_RATHOLE_BASE_DIR:-/data/venus-rathole}"
RC_LOCAL="${VENUS_RATHOLE_RC_LOCAL:-/data/rc.local}"
SERVICE_ROOT="${VENUS_RATHOLE_SERVICE_ROOT:-/service}"
SERVICE_NAME="venus-rathole"
MARKER_BEGIN="# BEGIN venus-rathole"
MARKER_END="# END venus-rathole"
GUI_DIR="${VENUS_RATHOLE_GUI_DIR:-/opt/victronenergy/gui/qml}"
PAGE_MAIN="$GUI_DIR/PageMain.qml"
PAGE_RATHOLE="$GUI_DIR/PageRathole.qml"
CREATED_TOKEN=""
unset CDPATH
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/rathole-release.sh"

die() {
    printf '%s\n' "Error: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: install.sh

Installs the Venus OS rathole client and creates an editable client.toml template.
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

generate_token() {
    [ -r /dev/urandom ] || die "/dev/urandom is required to generate a token"
    token=$(hexdump -n 4 -v -e '/1 "%02X"' /dev/urandom)
    [ "${#token}" -eq 8 ] || die "could not generate a token"
    printf '%s' "$token"
}

ensure_client_template() {
    [ -f "$BASE_DIR/client.toml" ] && return 0
    CREATED_TOKEN=$(generate_token)
    umask 077
    cat > "$BASE_DIR/client.toml" <<EOF
# Edit this file with: nano $BASE_DIR/client.toml
[client]
remote_addr = ""

# Use the same device token for every target on this GX.
[client.services.gx-ssh]
token = "$CREATED_TOKEN"
local_addr = "127.0.0.1:22"
EOF
    chmod 600 "$BASE_DIR/client.toml"
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

install_gui_page() {
    [ -f "$PAGE_MAIN" ] || return 0
    cp "$SCRIPT_DIR/../gui/qml/PageRathole.qml" "$PAGE_RATHOLE"
    chmod 0644 "$PAGE_RATHOLE"
    PAGE_MAIN="$PAGE_MAIN" python3 - <<'PY'
import os
import re
from pathlib import Path

path = Path(os.environ["PAGE_MAIN"])
text = path.read_text()
begin = "// BEGIN venus-rathole-ui"
end = "// END venus-rathole-ui"
block = '''\t\t\t// BEGIN venus-rathole-ui
\t\t\tMbSubMenu {
\t\t\t\tdescription: qsTr("Rathole")
\t\t\t\titem: VBusItem { value: [] }
\t\t\t\tMbTextBlock { item.bind: "com.victronenergy.rathole/StatusText"; width: 160; height: 25 }
\t\t\t\tsubpage: Component { PageRathole {} }
\t\t\t}
\t\t\t// END venus-rathole-ui'''

if begin in text or end in text:
    if begin not in text or end not in text:
        raise SystemExit("Incomplete existing Rathole UI marker")
    text = re.sub(r"\n?\s*// BEGIN venus-rathole-ui.*?\s*// END venus-rathole-ui", "", text, count=1, flags=re.S)

marker = '\t\t\tMbSubMenu {\n\t\t\t\tid: menuNotifications'
if marker not in text:
    raise SystemExit("Could not find the supported Notifications insertion point in PageMain.qml")
path.write_text(text.replace(marker, block + "\n\n" + marker, 1))
PY
    if command -v svc >/dev/null 2>&1 && [ -e /service/gui ]; then
        svc -t /service/gui >/dev/null 2>&1 || true
    fi
}

case "${1:-}" in
    "") ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
esac

case "$BASE_DIR" in
    /data/*) [ -d /data ] || die "this installer must run on Venus OS, where /data is persistent" ;;
esac
command -v unzip >/dev/null 2>&1 || die "unzip is required"

case "$(uname -m)" in
    armv7l|armv7*) select_rathole_release armv7 ;;
    *) die "unsupported architecture: $(uname -m); only validated armv7 Venus OS is supported" ;;
esac

temporary="${TMPDIR:-/tmp}/rathole-$SERVICE_NAME-$$.zip"
trap 'rm -f "$temporary"' EXIT INT TERM
mkdir -p "$BASE_DIR/bin" "$BASE_DIR/scripts" "$BASE_DIR/service"

if [ -n "${RATHOLE_ARCHIVE:-}" ]; then
    [ -r "$RATHOLE_ARCHIVE" ] || die "RATHOLE_ARCHIVE is not readable"
    cp "$RATHOLE_ARCHIVE" "$temporary"
else
    download "https://github.com/rathole-org/rathole/releases/download/$RATHOLE_VERSION/$RATHOLE_ASSET" "$temporary"
fi
verify_sha256 "$temporary" "$RATHOLE_SHA256"
unzip -p "$temporary" rathole > "$BASE_DIR/bin/rathole"
chmod 700 "$BASE_DIR/bin/rathole"

cp "$SCRIPT_DIR/start-service.sh" "$BASE_DIR/scripts/start-service.sh"
cp "$SCRIPT_DIR/uninstall.sh" "$BASE_DIR/scripts/uninstall.sh"
cp "$SCRIPT_DIR/rathole-release.sh" "$BASE_DIR/scripts/rathole-release.sh"
cp "$SCRIPT_DIR/../service/rathole-manager.py" "$BASE_DIR/rathole-manager.py"
rm -f "$BASE_DIR/scripts/configure.sh"
chmod 700 "$BASE_DIR/scripts/start-service.sh" "$BASE_DIR/scripts/uninstall.sh" "$BASE_DIR/scripts/rathole-release.sh" "$BASE_DIR/rathole-manager.py"
ensure_client_template
cat > "$BASE_DIR/service/run" <<EOF
#!/bin/sh
exec python3 "$BASE_DIR/rathole-manager.py" >/dev/null 2>&1
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
    uninstall) exec "$BASE_DIR/scripts/uninstall.sh" ;;
    *)
        printf '%s\\n' "Usage: venus-rathole {status|start|stop|restart|uninstall}" >&2
        exit 1
        ;;
esac
EOF
chmod 700 "$BASE_DIR/venus-rathole"

install_boot_hook
"$BASE_DIR/scripts/start-service.sh"
if ! install_gui_page; then
    rm -f "$PAGE_RATHOLE"
    printf '%s\n' "GX menu integration was skipped: this PageMain.qml layout is not supported." >&2
fi
if [ -s "$BASE_DIR/client.toml" ] && command -v sv >/dev/null 2>&1; then
    sv restart "$SERVICE_ROOT/$SERVICE_NAME" >/dev/null 2>&1 || true
fi

printf '%s\n' "Installed rathole $RATHOLE_VERSION in $BASE_DIR."
printf '%s\n' "Edit targets with: nano $BASE_DIR/client.toml"
if [ -n "$CREATED_TOKEN" ]; then
    printf '%s\n' "Device token: $CREATED_TOKEN"
fi
