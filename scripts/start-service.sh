#!/bin/sh
set -eu

BASE_DIR="${VENUS_RATHOLE_BASE_DIR:-/data/venus-rathole}"
SERVICE_ROOT="${VENUS_RATHOLE_SERVICE_ROOT:-/service}"
SERVICE_NAME="venus-rathole"
SERVICE_DIR="$BASE_DIR/service"
SERVICE_LINK="$SERVICE_ROOT/$SERVICE_NAME"

[ -x "$SERVICE_DIR/run" ] || exit 0
mkdir -p "$SERVICE_ROOT"
rm -f "$SERVICE_LINK"
ln -s "$SERVICE_DIR" "$SERVICE_LINK"
