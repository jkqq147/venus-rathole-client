# Venus Rathole Client

[English](README.md)

在 Victron Venus OS 上安装持久运行的 [rathole](https://github.com/rathole-org/rathole) 客户端，用于内网穿透。

**当前支持平台：** CCGX / `armv7l`，已在 Venus OS `v3.55` 验证。其他 Venus 硬件在完成实机验证前不支持。

本项目只管理 GX 设备端。服务端地址、公网端口和访问控制全部由你自己的 rathole 服务端决定。一台 GX 可暴露多个本机服务，并且它们共用一个短设备令牌。

## 安装

先按 Victron 官方文档开启 SSH，然后以 `root` 登录 GX，运行：

```sh
wget -qO- https://raw.githubusercontent.com/jkqq147/venus-rathole-client/master/install.sh | sh
```

### 离线手动安装

GX 无法访问 GitHub 时，在 Mac 下载[最新 Release](https://github.com/jkqq147/venus-rathole-client/releases/latest)中的 `armv7` `.tar.gz` 安装包及对应 `.tar.gz.sha256` 文件，然后直接运行：

```sh
cd ~/Downloads
shasum -a 256 -c venus-rathole-client-v0.1.1-armv7.tar.gz.sha256
scp venus-rathole-client-v0.1.1-armv7.tar.gz root@GX_IP:/tmp/
ssh root@GX_IP 'cd /tmp && tar -xzf venus-rathole-client-v0.1.1-armv7.tar.gz && sh venus-rathole-client-v0.1.1-armv7/offline-install.sh'
```

脚本会下载指定版本的官方 rathole 二进制、校验 SHA-256、安装到 `/data/venus-rathole`，生成短设备令牌和可编辑的配置模板。安装完成后立即生效，不需要重启。

然后编辑配置：

```sh
nano /data/venus-rathole/client.toml
```

填写 `remote_addr`，并按同一格式增加 target。每个 target 使用不同服务名和本机地址，但保持同一个设备 token：

```toml
[client]
remote_addr = "tunnel.example.com:2333"

[client.services.gx-boat-01-ssh]
token = "A1B2C3D4"
local_addr = "127.0.0.1:22"

[client.services.gx-boat-01-web]
token = "A1B2C3D4"
local_addr = "127.0.0.1:80"
```

## 日常命令

```sh
/data/venus-rathole/venus-rathole status
/data/venus-rathole/venus-rathole restart
/data/venus-rathole/venus-rathole uninstall
```

保存 `client.toml` 后运行 `restart`。重启 GX 后服务会自动恢复。GX 的 Rathole 页面会显示本机进程状态、服务器、设备令牌和 target 数量，并可直接选择启用或停用。

安装后客户端默认关闭。完成配置后，在 GX 的 Rathole 页面将 `Client` 设为 `Enabled` 即可启动。rathole 负责与服务端持续重连；`Client running` 只表示本机客户端进程正在运行，不表示公网端口已经验证可访问。

## 版本策略

rathole 固定为 `v0.5.0`，并校验各架构的 SHA-256。安装脚本不会跟随可能变化的 `latest` 版本。维护者升级流程见 [维护说明](docs/MAINTENANCE.md)。

## 服务端

服务端由你自行部署和管理。可参考 [docs/server-example.toml](docs/server-example.toml)：服务端为每个 target 定义服务名和公网监听端口；同一 GX 的 target 复用一个设备令牌。

本包装脚本采用 MIT 许可证；下载的 rathole 保持上游原样，采用 Apache-2.0 许可证。
