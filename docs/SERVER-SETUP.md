# Server Setup

This is the verified server path for Ubuntu x86_64 with systemd. It runs the
same pinned rathole version as the GX client, `v0.5.0`. Other server platforms
need the matching upstream rathole asset and are not covered here.

## 1. Install rathole

Run on the public server as a sudo-capable user:

```sh
sudo apt-get update
sudo apt-get install -y curl unzip

tmpdir=$(mktemp -d)
curl -fL -o "$tmpdir/rathole.zip" \
  https://github.com/rathole-org/rathole/releases/download/v0.5.0/rathole-x86_64-unknown-linux-gnu.zip
unzip -q "$tmpdir/rathole.zip" -d "$tmpdir"
sudo install -m 0755 "$tmpdir/rathole" /usr/local/bin/rathole
rm -rf "$tmpdir"

sudo useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin rathole
sudo install -d -o rathole -g rathole -m 0750 /etc/rathole
```

## 2. Create the server configuration

Use a unique token from the GX file `/data/venus-rathole/client.toml`. The
service name, token, and public port must match the GX configuration.

```sh
sudo nano /etc/rathole/server.toml
```

For one SSH target, enter the following and replace the example token:

```toml
[server]
bind_addr = "0.0.0.0:2333"

[server.services.gx-ssh]
token = "A1B2C3D4"
bind_addr = "0.0.0.0:22201"
```

`2333` is the rathole control port. `22201` is the public port for this one
target. Add one `[server.services.<name>]` block for every extra target, each
with a different public port. Targets on the same GX normally share one token.

Restrict the configuration so only the service can read its tokens:

```sh
sudo chown root:rathole /etc/rathole/server.toml
sudo chmod 0640 /etc/rathole/server.toml
```

## 3. Create and start the system service

```sh
sudo tee /etc/systemd/system/rathole.service >/dev/null <<'EOF'
[Unit]
Description=Rathole reverse tunnel server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=rathole
Group=rathole
ExecStart=/usr/local/bin/rathole --server /etc/rathole/server.toml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now rathole
sudo systemctl status --no-pager rathole
```

## 4. Allow the ports

Allow TCP `2333` and every public service port in both the server firewall and
your cloud provider security group. For the example above, those are `2333`
and `22201`.

## 5. Match the GX configuration

On the GX, edit `/data/venus-rathole/client.toml` so the server address,
service name, and token match the server configuration:

```toml
[client]
remote_addr = "tunnel.example.com:2333"

[client.services.gx-ssh]
token = "A1B2C3D4"
local_addr = "127.0.0.1:22"
```

`gx-ssh` is the service included in a new GX template. If you rename it, use
the same new name on both sides. Do not leave an unmatched client service.

Restart the client, then enable it from the GX Rathole page:

```sh
/data/venus-rathole/venus-rathole restart
/data/venus-rathole/venus-rathole status
```

Confirm the server sees the listener:

```sh
sudo ss -ltnp | grep -E ':(2333|22201)'
```

Then connect to `tunnel.example.com:22201`. The service automatically
reconnects after either the server service or GX restarts.
