#!/bin/sh
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

remove_boot_hook() {
    [ -f "$RC_LOCAL" ] || return 0
    temporary="$RC_LOCAL.venus-rathole.$$"
    sed "/^$MARKER_BEGIN$/,/^$MARKER_END$/d" "$RC_LOCAL" > "$temporary"
    mv "$temporary" "$RC_LOCAL"
    chmod +x "$RC_LOCAL"
}

remove_boot_hook
rm -f "$SERVICE_ROOT/$SERVICE_NAME"
rm -rf "$BASE_DIR"
if [ -f "$PAGE_MAIN" ]; then
    temporary="$PAGE_MAIN.venus-rathole.$$"
    sed '/^[[:space:]]*\/\/ BEGIN venus-rathole-ui$/,/^[[:space:]]*\/\/ END venus-rathole-ui$/d' "$PAGE_MAIN" > "$temporary"
    mv "$temporary" "$PAGE_MAIN"
    if command -v svc >/dev/null 2>&1 && [ -e /service/gui ]; then
        svc -t /service/gui >/dev/null 2>&1 || true
    fi
fi
rm -f "$PAGE_RATHOLE"
printf '%s\n' "Removed $SERVICE_NAME."
