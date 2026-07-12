# Venus Rathole Client

[中文](README.zh-CN.md)

Install [rathole](https://github.com/rathole-org/rathole) as a persistent, client-only reverse-tunnel service on Victron Venus OS.

The repository owns only the GX client. You keep control of the rathole server, public ports, and device access policy. One server can serve many GX devices: give every device its own service name and token.

## Install

SSH to the GX as `root`, then run:

```sh
wget -qO- https://raw.githubusercontent.com/jkqq147/venus-rathole-client/master/install.sh | sh
```

The installer downloads the pinned upstream rathole release, verifies its SHA-256 checksum, installs it under `/data/venus-rathole`, generates a short device token when one is not supplied, and installs a native GX settings page. No reboot is required.

## Everyday commands

```sh
/data/venus-rathole/venus-rathole status
/data/venus-rathole/venus-rathole configure
/data/venus-rathole/venus-rathole restart
/data/venus-rathole/venus-rathole uninstall
```

The service starts automatically after reboot. Its GX settings page shows the local process status, server, device service, local target, and device token; it also provides an Enabled/Disabled control.

## Server configuration

Configure the server independently. A minimal server-side example is in [docs/server-example.toml](docs/server-example.toml). The client only needs the server address, service name, token, and local target such as `127.0.0.1:22`.

This wrapper is MIT-licensed. Rathole is downloaded unchanged from its upstream release and is licensed under Apache-2.0.
