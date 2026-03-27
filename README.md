# CEC Tools

服务器翻墙工具一键安装脚本。

## 功能特性

- **V2Ray**: VMess 协议，支持多种传输方式（KCP、WebSocket 等）
- **Clash Meta**: 支持 TUN 透明代理，智能分流

## 快速开始

### 一键安装

```bash
curl -fsSL https://cec.cc/tools/v2ray/install.sh | bash
source ~/.bashrc
```

## 使用方法

### V2Ray

```bash
v2rayc start        # 启动 V2Ray
v2rayc stop         # 停止 V2Ray
v2rayc status       # 查看状态
v2rayc test         # 测试连接
v2rayc config       # 编辑配置
v2rayc on           # 开启代理（当前终端）
v2rayc off          # 关闭代理
v2rayc docker-build # Docker 构建使用代理
v2rayc uninstall    # 卸载
```

### Clash Meta

```bash
clashc start    # 启动 Clash
clashc stop     # 停止 Clash
clashc status   # 查看状态
clashc test     # 测试连接
clashc config   # 编辑配置
```

## 目录结构

```
cec-tools/
├── clash/
│   ├── install.sh      # Clash 安装脚本
│   └── data/           # 配置文件和GeoIP数据
└── v2ray/
    ├── install.sh      # V2Ray 安装脚本
    └── data/           # 配置文件和GeoIP数据
```

## 配置文件位置

- **V2Ray**: `~/.config/v2ray/config.json`
- **Clash**: `~/.config/clashc/config.yaml`

## 注意事项

1. 本工具仅供服务器内部网络加速使用
2. 请遵守当地法律法规
3. 默认配置已包含团队节点，开箱即用
4. 首次使用请先运行 `source ~/.bashrc` 加载环境