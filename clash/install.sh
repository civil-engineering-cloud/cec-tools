#!/bin/bash
# Clash Meta (clashc) 一键安装脚本
# 用法: curl -fsSL https://cec.cc/tools/clash/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Clash Meta (clashc) 一键安装${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检测是否 root
if [[ $EUID -eq 0 ]]; then
    BIN_DIR="/usr/local/bin"
    CONF_DIR="/etc/clashc"
else
    BIN_DIR="$HOME/.local/bin"
    CONF_DIR="$HOME/.config/clashc"
fi

# 自动检测下载源
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
if [[ "$SCRIPT_SOURCE" == *"localhost"* ]] || [[ "$SCRIPT_SOURCE" == *"127.0.0.1"* ]]; then
    DOWNLOAD_BASE="http://localhost:8410/tools/clash"
elif [[ "$SCRIPT_SOURCE" == *"cec.cc"* ]]; then
    DOWNLOAD_BASE="https://cec.cc/tools/clash"
else
    DOWNLOAD_BASE="http://tools.cec.cc:8410/tools/clash"
fi

echo "下载源: $DOWNLOAD_BASE"
echo "安装目录: $BIN_DIR"
echo ""

# 版本信息
CLASHC_VERSION="v1.18.1"

# 检测架构
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH_SUFFIX="amd64"
        ;;
    aarch64|arm64)
        ARCH_SUFFIX="arm64"
        ;;
    *)
        echo -e "${RED}不支持的架构: $ARCH${NC}"
        exit 1
        ;;
esac

echo "检测到系统架构: $ARCH ($ARCH_SUFFIX)"
echo ""

# 步骤 1: 下载并安装 clash-meta
echo -e "${BLUE}[1/4] 下载 Clash Meta...${NC}"

CLASHC_FILE="clashc-linux-${ARCH_SUFFIX}-${CLASHC_VERSION}.gz"
DOWNLOAD_URL="${DOWNLOAD_BASE}/bin/${CLASHC_FILE}"
TEMP_DIR=$(mktemp -d)
TEMP_FILE="$TEMP_DIR/$CLASHC_FILE"

echo "下载地址: $DOWNLOAD_URL"
if wget -q --show-progress -O "$TEMP_FILE" "$DOWNLOAD_URL" 2>&1; then
    echo -e "${GREEN}✓ 下载成功${NC}"
else
    echo -e "${RED}✗ 下载失败${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo -e "${BLUE}[2/4] 解压并安装...${NC}"

gunzip -f "$TEMP_FILE"
CLASHC_BIN="$TEMP_DIR/clashc-linux-${ARCH_SUFFIX}-${CLASHC_VERSION}"
mkdir -p "$BIN_DIR"
mv "$CLASHC_BIN" "$BIN_DIR/clash-meta"
chmod +x "$BIN_DIR/clash-meta"

# 创建软链接
ln -sf "$BIN_DIR/clash-meta" "$BIN_DIR/clash"
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✓ 安装完成${NC}"

echo ""

# 步骤 2: 创建 clashc 命令
echo -e "${BLUE}[3/4] 创建 clashc 命令...${NC}"

cat > "$BIN_DIR/clashc" << 'CLASHC_EOF'
#!/bin/bash
# Clashc 统一管理命令

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -eq 0 ]]; then
    BIN_DIR="/usr/local/bin"
    CONF_DIR="/etc/clashc"
else
    BIN_DIR="$HOME/.local/bin"
    CONF_DIR="$HOME/.config/clashc"
fi

CONFIG_FILE="$CONF_DIR/config.yaml"
LOG_FILE="$CONF_DIR/clash.log"

show_help() {
    echo -e "${BLUE}Clashc - Clash Meta 管理命令${NC}"
    echo ""
    echo "用法: clashc <命令>"
    echo ""
    echo "命令:"
    echo -e "  ${GREEN}start${NC}        启动 Clash"
    echo -e "  ${GREEN}stop${NC}         停止 Clash"
    echo -e "  ${GREEN}status${NC}       查看状态"
    echo -e "  ${GREEN}test${NC}         测试连接"
    echo -e "  ${GREEN}config${NC}       编辑配置"
    echo -e "  ${GREEN}uninstall${NC}    卸载"
    echo -e "  ${GREEN}help${NC}         显示帮助"
}

stop_clash() {
    if pgrep -x "clash-meta" > /dev/null; then
        pkill clash-meta
        sleep 1
        echo -e "${GREEN}✓ Clash 已停止${NC}"
    else
        echo -e "${YELLOW}Clash 未运行${NC}"
    fi
}

start_clash() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}配置文件不存在: $CONFIG_FILE${NC}"
        echo "请先配置: clashc config"
        exit 1
    fi

    if pgrep -x "clash-meta" > /dev/null; then
        echo -e "${YELLOW}Clash 已在运行${NC}"
        return
    fi

    nohup "$BIN_DIR/clash-meta" -d "$CONF_DIR" > "$LOG_FILE" 2>&1 &
    sleep 2

    if pgrep -x "clash-meta" > /dev/null; then
        echo -e "${GREEN}✓ Clash 已启动${NC}"
    else
        echo -e "${RED}✗ Clash 启动失败${NC}"
        echo "查看日志: tail -f $LOG_FILE"
    fi
}

uninstall_clash() {
    echo -e "${YELLOW}正在卸载 Clash...${NC}"
    stop_clash
    rm -f "$BIN_DIR/clash-meta" "$BIN_DIR/clash" "$BIN_DIR/clashc"
    rm -rf "$CONF_DIR"
    echo -e "${GREEN}✓ Clash 已卸载${NC}"
}

case "${1:-help}" in
    start)
        start_clash
        ;;
    stop)
        stop_clash
        ;;
    status)
        if pgrep -x "clash-meta" > /dev/null; then
            echo -e "${GREEN}✓ Clash 运行中${NC}"
        else
            echo -e "${YELLOW}Clash 未运行${NC}"
        fi
        ;;
    test)
        echo "测试连接..."
        if curl -x http://127.0.0.1:7890 -s -m 5 https://www.google.com > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 测试成功${NC}"
        else
            echo -e "${RED}✗ 测试失败${NC}"
        fi
        ;;
    config)
        mkdir -p "$CONF_DIR"
        ${EDITOR:-nano} "$CONFIG_FILE"
        ;;
    uninstall)
        uninstall_clash
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
CLASHC_EOF

chmod +x "$BIN_DIR/clashc"
echo -e "${GREEN}✓ clashc 命令已创建${NC}"

echo ""

# 步骤 3: 配置
echo -e "${BLUE}[4/4] 配置...${NC}"

mkdir -p "$CONF_DIR"

# 下载 GeoIP
echo "下载 GeoIP 数据库..."
GEOIP_URL="${DOWNLOAD_BASE}/data/geoip.dat"
GEOSITE_URL="${DOWNLOAD_BASE}/data/geosite.dat"

if wget -q -O "$CONF_DIR/geoip.dat" "$GEOIP_URL" 2>/dev/null; then
    echo -e "${GREEN}✓ GeoIP.dat 下载成功${NC}"
fi

if wget -q -O "$CONF_DIR/geosite.dat" "$GEOSITE_URL" 2>/dev/null; then
    echo -e "${GREEN}✓ GeoSite.dat 下载成功${NC}"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_URL="${DOWNLOAD_BASE}/data/config.yaml.example"
    if wget -q -O "$CONF_DIR/config.yaml" "$CONFIG_URL" 2>/dev/null; then
        echo -e "${GREEN}✓ 配置模板下载成功${NC}"
    fi
    echo -e "${YELLOW}请编辑配置: clashc config${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Clashc 安装成功！${NC}"
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
echo "  clashc start        # 启动 Clash"
echo "  clashc stop         # 停止 Clash"
echo "  clashc status       # 查看状态"
echo "  clashc test         # 测试连接"
echo "  clashc config       # 编辑配置"
echo ""
echo -e "${YELLOW}配置文件: $CONFIG_FILE${NC}"
echo ""