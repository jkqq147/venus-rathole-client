# Venus Rathole Client

[中文](README.zh-CN.md)

Install [rathole](https://github.com/rathole-org/rathole) as a persistent, client-only reverse-tunnel service on Victron Venus OS.

**Supported platform:** CCGX / `armv7l`, validated on Venus OS `v3.55`. Other Venus hardware is not supported until it has been tested.

The repository owns only the GX client. You keep control of the rathole server, public ports, and device access policy. One GX can expose multiple local targets with one short device token.

## Install

SSH to the GX as `root`, then run:

```sh
wget -qO- https://raw.githubusercontent.com/jkqq147/venus-rathole-client/master/install.sh | sh
```

### Offline Manual Install

For a GX without GitHub access, download the `armv7` `.tar.gz` package and its
`.tar.gz.sha256` file from the [latest release](https://github.com/jkqq147/venus-rathole-client/releases/latest), then run:

```sh
cd ~/Downloads
shasum -a 256 -c venus-rathole-client-v0.1.1-armv7.tar.gz.sha256
scp venus-rathole-client-v0.1.1-armv7.tar.gz root@GX_IP:/tmp/
ssh root@GX_IP 'cd /tmp && tar -xzf venus-rathole-client-v0.1.1-armv7.tar.gz && sh venus-rathole-client-v0.1.1-armv7/offline-install.sh'
```

The repository package includes the pinned upstream rathole binary. The installer verifies its SHA-256 checksum, installs it under `/data/venus-rathole`, creates a short device token and editable configuration template, and installs a native GX settings page. No reboot is required.

Then edit the rathole-native configuration with `nano /data/venus-rathole/client.toml`. Use one device token for all local targets on that GX; each target needs its own service name and server-side public port.

## Everyday commands

```sh
/data/venus-rathole/venus-rathole status
/data/venus-rathole/venus-rathole restart
/data/venus-rathole/venus-rathole uninstall
```

The service starts automatically after reboot. Its GX settings page shows the local process status, server, device token, and target count; it also provides an Enabled/Disabled control.

The client is disabled after a new installation. After editing `client.toml`, set `Client` to `Enabled` on the GX page. Rathole owns server reconnection; `Client running` means the local client process is running, not that a public port has been independently verified.

## Uninstall

```sh
/data/venus-rathole/venus-rathole uninstall
```

This removes the client, configuration, boot hook, and GX menu entry.

## Version Policy

Rathole is pinned to `v0.5.0` and checked against architecture-specific SHA-256 digests. The installer never follows a moving `latest` release. See [maintenance notes](docs/MAINTENANCE.md) for the verified update process.

## Server configuration

The GX client needs a public rathole server before it can connect. Follow the
[Ubuntu server setup](docs/SERVER-SETUP.md) for the verified x86_64 + systemd
path. It installs the pinned rathole version, creates a server service, and
shows the required firewall and GX configuration.

Each GX target has a matching server-side service name and token. The server
binds the public port; the GX configuration supplies the local target. A compact
multi-target template is available in [docs/server-example.toml](docs/server-example.toml).

This wrapper is MIT-licensed. Rathole is downloaded unchanged from its upstream release and is licensed under Apache-2.0.
