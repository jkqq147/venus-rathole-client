# Maintenance

## Upstream version policy

The installer is intentionally pinned to one upstream rathole release and the
SHA-256 digest of each supported architecture asset. It never follows an
upstream `latest` label at install time.

To update rathole:

1. Select a tagged upstream release.
2. Download the `armv7-unknown-linux-musleabihf` and
   `aarch64-unknown-linux-musl` ZIP assets from that release.
3. Calculate their SHA-256 digests and update `scripts/install.sh` in the same
   commit as `RATHOLE_VERSION`.
4. Run the repository validation commands and test the installer on a Venus GX
   before publishing the update.

Users update by rerunning the normal installation command. They do not need to
choose an upstream version or override a version environment variable.

