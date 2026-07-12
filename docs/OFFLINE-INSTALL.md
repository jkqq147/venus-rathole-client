# Offline Install

Offline packages are published as GitHub Release assets and can be mirrored to
any trusted server. They are not committed to the source repository.

Choose the package matching the GX architecture: `armv7` for CCGX and most
current GX devices, or `aarch64` for 64-bit GX hardware. Verify the adjacent
`.sha256` file before copying the package to the GX.

```sh
scp venus-rathole-client-v0.5.0-armv7.tar.gz root@GX_IP:/tmp/
ssh root@GX_IP 'cd /tmp && tar -xzf venus-rathole-client-v0.5.0-armv7.tar.gz && sh venus-rathole-client-v0.5.0-armv7/offline-install.sh'
```

The offline installer uses the bundled, checksum-verified upstream rathole ZIP;
the GX does not need GitHub access.

Maintainers create a package with:

```sh
sh scripts/package-offline.sh armv7
sh scripts/package-offline.sh aarch64
```

