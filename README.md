# CEC Tools

服务器翻墙工具一键安装脚本。

## 功能特性

- **Clash Meta**: 支持 TUN 透明代理，智能分流
- **V2Ray**: VMess 协议，支持多种传输方式

## 快速开始

### 一键安装全部工具

```bash
curl -fsSL https://cec.cc/tools/install.sh | bash
```

### 单独安装

#### 安装 Clash Meta

```bash
curl -fsSL https://cec.cc/tools/clash/install.sh | bash
```

#### 安装 V2Ray

```bash
curl -fsSL https://cec.cc/tools/v2ray/install.sh | bash
```

## 使用方法

### Clash Meta

```bash
clashc start    # 启动服务
clashc stop     # 停止服务
clashc status   # 查看状态
clashc test     # 测试连接
```

### V2Ray

```bash
v2rayc start           # 启动透明代理
v2rayc stop            # 停止透明代理
v2rayc status           # 查看状态
v2rayc test            # 测试连接
v2rayc docker-build     # Docker 构建使用代理
```

## 架构说明

```
cec-tools/
├── install.sh          # 主安装脚本
├── clash/
│   ├── install.sh      # Clash 安装脚本
│   ├── bin/            # Clash 二进制文件
│   └── data/           # 配置文件和GeoIP数据
│       └── config.yaml.example
└── v2ray/
    ├── install.sh      # V2Ray 安装脚本
    └── bin/            # V2Ray 二进制文件
```

## 注意事项

1. 本工具仅供服务器内部网络加速使用
2. 请遵守当地法律法规
3. 配置文件中的节点信息需要替换为有效的节点