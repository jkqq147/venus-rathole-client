#!/bin/sh
# shellcheck disable=SC2034

RATHOLE_VERSION="v0.5.0"

select_rathole_release() {
    case "$1" in
        armv7)
            RATHOLE_ASSET="rathole-armv7-unknown-linux-musleabihf.zip"
            RATHOLE_SHA256="e8662d80d2cc9acc5f8f4d8a1c1a5ff7717b2fa71919a405d0eed8b64c8c1d88"
            ;;
        aarch64)
            RATHOLE_ASSET="rathole-aarch64-unknown-linux-musl.zip"
            RATHOLE_SHA256="fa4a6fc63d86f8f1faa7c103a845e4715ce79a048455c0eec897b27237576564"
            ;;
        *) return 1 ;;
    esac
}
