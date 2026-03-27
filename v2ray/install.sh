#!/bin/bash
# V2RayC 一键安装脚本（用户目录版，无需 sudo）
# 使用方法: curl -fsSL https://cec.cc/tools/v2ray/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}V2RayC 智能安装${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检测是否 root
if [[ $EUID -eq 0 ]]; then
    BIN_DIR="/usr/local/bin"
    SHARE_DIR="/usr/local/share/v2ray"
    ETC_DIR="/usr/local/etc/v2ray"
else
    BIN_DIR="$HOME/.local/bin"
    SHARE_DIR="$HOME/.local/share/v2ray"
    ETC_DIR="$HOME/.config/v2ray"
fi

# 自动检测下载源
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
if [[ "$SCRIPT_SOURCE" == *"localhost"* ]] || [[ "$SCRIPT_SOURCE" == *"127.0.0.1"* ]]; then
    DOWNLOAD_BASE="http://localhost:8410/tools/v2ray"
elif [[ "$SCRIPT_SOURCE" == *"cec.cc"* ]]; then
    DOWNLOAD_BASE="https://cec.cc/tools/v2ray"
else
    DOWNLOAD_BASE="http://tools.cec.cc:8410/tools/v2ray"
fi

echo "下载源: $DOWNLOAD_BASE"
echo "安装目录: $BIN_DIR"
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
        echo -e "${RED}错误: 不支持的架构 $ARCH${NC}"
        exit 1
        ;;
esac

echo "检测到系统架构: $ARCH"
echo ""

# 步骤 1: 安装 V2Ray 核心
echo -e "${BLUE}[1/4] 安装 V2Ray 核心...${NC}"

if [[ -f "$BIN_DIR/v2ray" ]] || command -v v2ray &> /dev/null; then
    echo -e "${YELLOW}V2Ray 已安装，跳过${NC}"
else
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    echo -e "${YELLOW}正在下载 V2Ray...${NC}"
    MIRRORS=(
        "${DOWNLOAD_BASE}/bin/${V2RAY_ZIP}"
        "https://ghproxy.com/https://github.com/v2fly/v2ray-core/releases/download/v5.44.1/${V2RAY_ZIP}"
        "https://github.com/v2fly/v2ray-core/releases/download/v5.44.1/${V2RAY_ZIP}"
    )

    DOWNLOAD_SUCCESS=false
    for MIRROR_URL in "${MIRRORS[@]}"; do
        if curl -fL --progress-bar --connect-timeout 30 --max-time 120 -o "$V2RAY_ZIP" "$MIRROR_URL" 2>&1; then
            FILE_SIZE=$(stat -c%s "$V2RAY_ZIP" 2>/dev/null || echo "0")
            if [[ "$FILE_SIZE" -gt 10485760 ]] && unzip -t "$V2RAY_ZIP" > /dev/null 2>&1; then
                DOWNLOAD_SUCCESS=true
                break
            fi
        fi
    done

    if [[ "$DOWNLOAD_SUCCESS" == "false" ]]; then
        echo -e "${RED}错误: V2Ray 下载失败${NC}"
        cd - > /dev/null
        rm -rf "$TMP_DIR"
        exit 1
    fi

    unzip -q "$V2RAY_ZIP"
    mkdir -p "$BIN_DIR" "$SHARE_DIR" "$ETC_DIR"
    cp v2ray "$BIN_DIR/v2ray"
    chmod +x "$BIN_DIR/v2ray"

    cd - > /dev/null
    rm -rf "$TMP_DIR"

    echo -e "${GREEN}✓ V2Ray 安装完成${NC}"
fi

echo ""

# 步骤 2: 安装 geo 数据
echo -e "${BLUE}[2/4] 安装 Geo 数据...${NC}"

mkdir -p "$SHARE_DIR"
curl -fsSL -o "$SHARE_DIR/geoip.dat" "${DOWNLOAD_BASE}/data/geoip.dat" 2>/dev/null || true
curl -fsSL -o "$SHARE_DIR/geosite.dat" "${DOWNLOAD_BASE}/data/geosite.dat" 2>/dev/null || true
echo -e "${GREEN}✓ Geo 数据安装完成${NC}"

echo ""

# 步骤 3: 创建 v2rayc 命令
echo -e "${BLUE}[3/4] 创建 v2rayc 命令...${NC}"

mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/v2rayc" << 'V2RAYC_EOF'
#!/bin/bash
# V2RayC 统一命令入口

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -eq 0 ]]; then
    BIN_DIR="/usr/local/bin"
    SHARE_DIR="/usr/local/share/v2ray"
    ETC_DIR="/usr/local/etc/v2ray"
    LOG_DIR="/var/log/v2ray"
else
    BIN_DIR="$HOME/.local/bin"
    SHARE_DIR="$HOME/.local/share/v2ray"
    ETC_DIR="$HOME/.config/v2ray"
    LOG_DIR="$HOME/.config/v2ray"
fi

CONFIG_FILE="$ETC_DIR/config.json"
LOG_FILE="$LOG_DIR/v2ray.log"

show_help() {
    echo -e "${BLUE}V2RayC - 服务器翻墙工具${NC}"
    echo ""
    echo "用法: v2rayc <命令>"
    echo ""
    echo "命令:"
    echo -e "  ${GREEN}start${NC}        启动 V2Ray"
    echo -e "  ${GREEN}stop${NC}         停止 V2Ray"
    echo -e "  ${GREEN}status${NC}       查看状态"
    echo -e "  ${GREEN}test${NC}         测试连接"
    echo -e "  ${GREEN}config${NC}       编辑配置"
    echo -e "  ${GREEN}on${NC}           开启代理（当前终端）"
    echo -e "  ${GREEN}off${NC}          关闭代理"
    echo -e "  ${GREEN}docker-build${NC}  Docker 构建使用代理"
    echo -e "  ${GREEN}uninstall${NC}    卸载 V2Ray"
    echo -e "  ${GREEN}help${NC}         显示帮助"
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

    nohup "$BIN_DIR/v2ray" run -config "$CONFIG_FILE" > "$LOG_FILE" 2>&1 &
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
    export HTTP_PROXY=http://127.0.0.1:1081
    export HTTPS_PROXY=http://127.0.0.1:1081
    echo -e "${GREEN}✓ 代理已开启${NC}"
}

proxy_off() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    echo -e "${GREEN}✓ 代理已关闭${NC}"
}

uninstall_v2ray() {
    echo -e "${YELLOW}正在卸载 V2Ray...${NC}"
    stop_v2ray
    rm -f "$BIN_DIR/v2ray" "$BIN_DIR/v2rayc"
    rm -rf "$SHARE_DIR" "$ETC_DIR"
    echo -e "${GREEN}✓ V2Ray 已卸载${NC}"
}

docker_build() {
    HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    if [[ -z "$HOST_IP" ]]; then
        HOST_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -n1)
    fi

    if [[ -z "$HOST_IP" ]]; then
        echo -e "${RED}错误: 无法获取宿主机 IP${NC}"
        exit 1
    fi

    echo -e "${BLUE}Docker 构建（使用代理）${NC}"
    echo -e "宿主机 IP: ${GREEN}$HOST_IP${NC}"
    echo ""

    HTTP_PROXY="http://$HOST_IP:1081" \
    HTTPS_PROXY="http://$HOST_IP:1081" \
    docker compose "$@" build
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
        mkdir -p "$ETC_DIR"
        ${EDITOR:-nano} "$CONFIG_FILE"
        ;;
    docker-build)
        shift
        docker_build "$@"
        ;;
    uninstall)
        uninstall_v2ray
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

chmod +x "$BIN_DIR/v2rayc"
echo -e "${GREEN}✓ v2rayc 命令已创建${NC}"

echo ""

# 步骤 4: 配置
echo -e "${BLUE}[4/4] 配置...${NC}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}创建默认配置...${NC}"
    mkdir -p "$ETC_DIR"
    printf '%s' '{"inbounds":[{"port":1080,"listen":"0.0.0.0","protocol":"socks","settings":{"udp":true}},{"port":1081,"listen":"0.0.0.0","protocol":"http"}],"outbounds":[{"protocol":"vmess","settings":{"vnext":[{"address":"YOUR_IP","port":8888,"users":[{"id":"YOUR_UUID","alterId":0}]}]},"streamSettings":{"network":"tcp"},"tag":"proxy"},{"protocol":"freedom","tag":"direct"}],"routing":{"domainStrategy":"IPIfNonMatch","rules":[{"type":"field","ip":["geoip:private","geoip:cn"],"outboundTag":"direct"},{"type":"field","domain":["geosite:cn"],"outboundTag":"direct"}]}}' > "$CONFIG_FILE"
    echo -e "${GREEN}✓ 默认配置已创建${NC}"
else
    echo -e "${GREEN}✓ 配置文件已存在${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}V2RayC 安装成功！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 添加到 PATH
BASHRC_LINE="export PATH=\"$BIN_DIR:\$PATH\""
if ! grep -q "$BIN_DIR" ~/.bashrc 2>/dev/null; then
    echo "$BASHRC_LINE" >> ~/.bashrc
    echo -e "${YELLOW}已添加 $BIN_DIR 到 PATH${NC}"
    echo -e "${YELLOW}运行: source ~/.bashrc${NC}"
fi

echo ""
echo "管理命令："
echo "  v2rayc start        # 启动 V2Ray"
echo "  v2rayc stop         # 停止 V2Ray"
echo "  v2rayc status       # 查看状态"
echo "  v2rayc test         # 测试连接"
echo "  v2rayc config       # 编辑配置"
echo "  v2rayc on           # 开启代理（当前终端）"
echo "  v2rayc off          # 关闭代理"
echo "  v2rayc docker-build # Docker 构建使用代理"
echo ""
echo -e "${YELLOW}配置文件: $CONFIG_FILE${NC}"
echo ""