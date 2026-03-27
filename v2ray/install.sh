#!/bin/bash
# V2Ray 一键安装脚本
# 用法: curl -fsSL http://tools.cec.cc:8410/tools/v2ray/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== V2Ray 一键安装脚本 ===${NC}"
echo ""

# 检查并安装依赖
if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}正在安装 unzip...${NC}"
    apt-get update -qq && apt-get install -y -qq unzip > /dev/null 2>&1
fi

# 自动检测下载源
SCRIPT_SOURCE="${BASH_SOURCE[0]}"

if [[ "$SCRIPT_SOURCE" == *"tools.cec.cc"* ]]; then
    DOWNLOAD_BASE="http://tools.cec.cc:8410/tools/v2ray"
elif [[ "$SCRIPT_SOURCE" == *"localhost"* ]] || [[ "$SCRIPT_SOURCE" == *"127.0.0.1"* ]]; then
    DOWNLOAD_BASE="http://localhost:8410/tools/v2ray"
else
    DOWNLOAD_BASE="http://tools.cec.cc:8410/tools/v2ray"
fi

echo "下载源: $DOWNLOAD_BASE"
echo ""

# 检测架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        V2RAY_ZIP="v2ray-linux-64.zip"
        ;;
    aarch64|arm64)
        V2RAY_ZIP="v2ray-linux-arm64-v8a.zip"
        ;;
    *)
        echo -e "${RED}不支持的架构: $ARCH${NC}"
        exit 1
        ;;
esac

echo "检测到系统架构: $ARCH"
echo ""

# 1. 安装 V2Ray 核心
echo -e "${GREEN}[1/3] 下载 V2Ray...${NC}"

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

V2RAY_URL="${DOWNLOAD_BASE}/bin/${V2RAY_ZIP}"

echo "下载地址: $V2RAY_URL"
if wget -q --show-progress -O "$V2RAY_ZIP" "$V2RAY_URL" 2>&1 || curl -fL --progress-bar -o "$V2RAY_ZIP" "$V2RAY_URL"; then
    echo -e "${GREEN}✓ 下载成功${NC}"
else
    echo -e "${RED}✗ 下载失败${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi

echo ""
echo -e "${GREEN}[2/3] 安装 V2Ray...${NC}"

unzip -q "$V2RAY_ZIP"
sudo mkdir -p /usr/local/bin /usr/local/share/v2ray
sudo cp v2ray /usr/local/bin/v2ray
sudo chmod +x /usr/local/bin/v2ray

cd - > /dev/null
rm -rf "$TMP_DIR"

echo -e "${GREEN}✓ V2Ray 安装完成${NC}"
echo ""

# 3. 创建 v2rayc 命令
echo -e "${GREEN}[3/3] 创建 v2rayc 命令...${NC}"

sudo tee /usr/local/bin/v2rayc > /dev/null << 'V2RAYC_EOF'
#!/bin/bash
# V2Ray 管理命令

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="/usr/local/etc/v2ray/config.json"
LOG_FILE="/var/log/v2ray.log"

show_help() {
    echo -e "${BLUE}V2Ray 管理命令${NC}"
    echo ""
    echo "用法: v2rayc <命令>"
    echo ""
    echo -e "  ${GREEN}start${NC}      启动 V2Ray"
    echo -e "  ${GREEN}stop${NC}       停止 V2Ray"
    echo -e "  ${GREEN}status${NC}     查看状态"
    echo -e "  ${GREEN}test${NC}       测试连接"
    echo -e "  ${GREEN}config${NC}     编辑配置"
    echo -e "  ${GREEN}on${NC}         开启 HTTP 代理（当前终端）"
    echo -e "  ${GREEN}off${NC}        关闭 HTTP 代理"
    echo -e "  ${GREEN}uninstall${NC}  卸载 V2Ray"
    echo -e "  ${GREEN}help${NC}       显示帮助"
}

stop_v2ray() {
    if pgrep -x "v2ray" > /dev/null; then
        pkill v2ray
        sleep 1
        echo -e "${GREEN}✓ V2Ray 已停止${NC}"
    else
        echo -e "${YELLOW}V2Ray 未运行${NC}"
    fi
}

uninstall_v2ray() {
    echo -e "${YELLOW}正在卸载 V2Ray...${NC}"
    stop_v2ray
    sudo rm -f /usr/local/bin/v2ray /usr/local/bin/v2rayc
    sudo rm -rf /usr/local/etc/v2ray /usr/local/share/v2ray
    echo -e "${GREEN}✓ V2Ray 已卸载${NC}"
}

start_v2ray() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}配置文件不存在: $CONFIG_FILE${NC}"
        echo "请先配置: v2rayc config"
        exit 1
    fi

    if pgrep -x "v2ray" > /dev/null; then
        echo -e "${YELLOW}V2Ray 已在运行${NC}"
        return
    fi

    nohup sudo /usr/local/bin/v2ray run -config "$CONFIG_FILE" > "$LOG_FILE" 2>&1 &
    sleep 2

    if pgrep -x "v2ray" > /dev/null; then
        echo -e "${GREEN}✓ V2Ray 已启动${NC}"
        echo -e "  SOCKS 代理: 127.0.0.1:1080"
        echo -e "  HTTP 代理:  127.0.0.1:1081"
    else
        echo -e "${RED}✗ V2Ray 启动失败${NC}"
        echo "查看日志: tail -f $LOG_FILE"
    fi
}

proxy_on() {
    export http_proxy=http://127.0.0.1:1081
    export https_proxy=http://127.0.0.1:1081
    echo -e "${GREEN}✓ HTTP 代理已开启（仅当前终端）${NC}"
    echo "  http_proxy=$http_proxy"
    echo "  https_proxy=$https_proxy"
}

proxy_off() {
    unset http_proxy https_proxy
    echo -e "${GREEN}✓ HTTP 代理已关闭${NC}"
}

case "${1:-help}" in
    start)
        start_v2ray
        ;;
    stop)
        stop_v2ray
        ;;
    on)
        proxy_on
        ;;
    off)
        proxy_off
        ;;
    uninstall)
        uninstall_v2ray
        ;;
    status)
        if pgrep -x "v2ray" > /dev/null; then
            echo -e "${GREEN}✓ V2Ray 运行中${NC}"
        else
            echo -e "${YELLOW}V2Ray 未运行${NC}"
        fi
        ;;
    test)
        echo "测试代理连接..."
        if curl -x http://127.0.0.1:1081 -s -m 5 https://www.google.com > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 代理测试成功${NC}"
        else
            echo -e "${RED}✗ 代理测试失败${NC}"
        fi
        ;;
    config)
        sudo mkdir -p /usr/local/etc/v2ray
        sudo ${EDITOR:-nano} "$CONFIG_FILE"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}未知命令: $1${NC}"
        show_help
        exit 1
        ;;
esac
V2RAYC_EOF

sudo chmod +x /usr/local/bin/v2rayc

echo -e "${GREEN}✓ v2rayc 命令已创建${NC}"
echo ""

# 4. 下载预设配置
echo -e "${GREEN}[4/4] 下载配置...${NC}"
sudo mkdir -p /usr/local/etc/v2ray /usr/local/share/v2ray

# 下载 geoip 和 geosite
sudo curl -fsSL -o /usr/local/share/v2ray/geoip.dat "${DOWNLOAD_BASE}/data/geoip.dat" 2>/dev/null || true
sudo curl -fsSL -o /usr/local/share/v2ray/geosite.dat "${DOWNLOAD_BASE}/data/geosite.dat" 2>/dev/null || true

# 下载预设配置（如果没有的话）
if [ ! -f /usr/local/etc/v2ray/config.json ]; then
    echo -e "${YELLOW}配置文件不存在，创建默认配置...${NC}"
    sudo tee /usr/local/etc/v2ray/config.json > /dev/null << 'CONFIG_EOF'
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {"listen": "0.0.0.0", "port": 1080, "protocol": "socks"},
    {"listen": "0.0.0.0", "port": 1081, "protocol": "http"}
  ],
  "outbounds": [
    {"protocol": "vmess", "settings": {"vnext": [{"address": "YOUR_SERVER", "port": 443, "users": [{"id": "YOUR_UUID"}]}]}},
    {"protocol": "freedom"}
  ]
}
CONFIG_EOF
    echo -e "${YELLOW}请编辑配置添加节点信息: sudo v2rayc config${NC}"
else
    echo -e "${GREEN}✓ 配置文件已存在${NC}"
fi

echo ""
echo -e "${GREEN}=== 安装完成 ===${NC}"
echo ""
echo "管理命令："
echo "  v2rayc start     # 启动 V2Ray"
echo "  v2rayc stop      # 停止 V2Ray"
echo "  v2rayc status    # 查看状态"
echo "  v2rayc test      # 测试连接"
echo "  v2rayc config    # 编辑配置"
echo "  v2rayc on        # 开启 HTTP 代理（当前终端）"
echo "  v2rayc off       # 关闭 HTTP 代理"
echo ""
echo -e "${YELLOW}首次使用请先配置节点: sudo v2rayc config${NC}"
echo ""