# Venus Rathole Client

[English](README.md)

在 Victron Venus OS 上安装持久运行的 [rathole](https://github.com/rathole-org/rathole) 客户端，用于内网穿透。

本项目只管理 GX 设备端。服务端地址、公网端口和访问控制全部由你自己的 rathole 服务端决定。一台服务端可服务多个 GX：每台设备使用不同的服务名和令牌即可。

## 安装

先按 Victron 官方文档开启 SSH，然后以 `root` 登录 GX，运行：

```sh
wget -qO- https://raw.githubusercontent.com/jkqq147/venus-rathole-client/master/install.sh | sh
```

脚本会下载指定版本的官方 rathole 二进制、校验 SHA-256、安装到 `/data/venus-rathole`，然后交互填写客户端配置。安装完成后立即生效，不需要重启。

需要填写的仅有：

- 服务端地址，例如 `tunnel.example.com:2333`
- 此设备的服务名，例如 `gx-boat-01`
- 服务端为该服务设置的令牌
- 本地目标地址，SSH 通常为 `127.0.0.1:22`

## 日常命令

```sh
/data/venus-rathole/venus-rathole status
/data/venus-rathole/venus-rathole configure
/data/venus-rathole/venus-rathole restart
/data/venus-rathole/venus-rathole uninstall
```

重启 GX 后服务会自动恢复。

## 服务端

服务端由你自行部署和管理。可参考 [docs/server-example.toml](docs/server-example.toml)：服务端为每台设备定义唯一的服务名、令牌和公网监听端口；设备端不保存或决定公网端口。

本包装脚本采用 MIT 许可证；下载的 rathole 保持上游原样，采用 Apache-2.0 许可证。
