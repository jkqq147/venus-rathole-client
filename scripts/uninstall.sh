#!/bin/sh
set -eu

BASE_DIR="${VENUS_RATHOLE_BASE_DIR:-/data/venus-rathole}"
RC_LOCAL="${VENUS_RATHOLE_RC_LOCAL:-/data/rc.local}"
SERVICE_ROOT="${VENUS_RATHOLE_SERVICE_ROOT:-/service}"
SERVICE_NAME="venus-rathole"
MARKER_BEGIN="# BEGIN venus-rathole"
MARKER_END="# END venus-rathole"

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
printf '%s\n' "Removed $SERVICE_NAME."
