# 服务端部署

这是已验证的 Ubuntu x86_64 + systemd 服务端路径，使用与 GX 客户端相同的固定版本 `rathole v0.5.0`。其他服务器系统需要自行选择上游对应架构的二进制，本项目暂不覆盖。

## 1. 安装 rathole

在公网服务器上，以可使用 `sudo` 的用户执行：

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

## 2. 创建服务端配置

从 GX 的 `/data/venus-rathole/client.toml` 获取设备 token。服务名、token 与公网端口必须与 GX 配置对应。

```sh
sudo nano /etc/rathole/server.toml
```

以下是一个 SSH target 的最小配置。将示例 token 替换为 GX 中实际生成的 token：

```toml
[server]
bind_addr = "0.0.0.0:2333"

[server.services.gx-ssh]
token = "A1B2C3D4"
bind_addr = "0.0.0.0:22201"
```

`2333` 是 rathole 控制端口，`22201` 是这个 target 的公网端口。每增加一个 target，就增加一个不同名称和不同公网端口的 `[server.services.<name>]` 块。同一台 GX 的多个 target 通常共用一个 token。

限制配置文件权限，使普通用户不能读取 token：

```sh
sudo chown root:rathole /etc/rathole/server.toml
sudo chmod 0640 /etc/rathole/server.toml
```

## 3. 创建并启动 systemd 服务

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

## 4. 放行端口

在服务器防火墙和云服务商安全组中，放行 TCP `2333` 及每个 target 的公网端口。以上例为例，需要放行 `2333` 和 `22201`。

## 5. 配置 GX 客户端

在 GX 上编辑 `/data/venus-rathole/client.toml`，使服务端地址、服务名和 token 与服务端完全一致：

```toml
[client]
remote_addr = "tunnel.example.com:2333"

[client.services.gx-ssh]
token = "A1B2C3D4"
local_addr = "127.0.0.1:22"
```

`gx-ssh` 是新安装时 GX 配置模板自带的服务名。若改名，服务端和 GX 必须使用相同的新名称，且不要保留服务端没有对应项的客户端服务。

重启客户端，然后在 GX 的 Rathole 页面将 Client 设为 Enabled：

```sh
/data/venus-rathole/venus-rathole restart
/data/venus-rathole/venus-rathole status
```

服务端可用以下命令确认端口已监听：

```sh
sudo ss -ltnp | grep -E ':(2333|22201)'
```

然后连接 `tunnel.example.com:22201`。服务端 rathole 或 GX 重启后，客户端会自动重连。
