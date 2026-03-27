#!/bin/bash
# Clash Meta 一键安装脚本
# 用法: curl -fsSL http://gw.cec.cc:8410/tools/clash/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CLASHC_VERSION="v1.18.1"

echo -e "${GREEN}=== Clash Meta (clashc) 一键安装脚本 ===${NC}"
echo ""

# 自动检测下载源
SCRIPT_SOURCE="${BASH_SOURCE[0]}"

if [[ "$SCRIPT_SOURCE" == *"gw.cec.cc"* ]]; then
    DOWNLOAD_BASE="http://gw.cec.cc:8410/tools/clash"
elif [[ "$SCRIPT_SOURCE" == *"localhost"* ]] || [[ "$SCRIPT_SOURCE" == *"127.0.0.1"* ]]; then
    DOWNLOAD_BASE="http://localhost:8410/tools/clash"
else
    DOWNLOAD_BASE="https://gw.cec.cc:8410/tools/clash"
fi

echo "下载源: $DOWNLOAD_BASE"
echo ""

# 检测系统架构
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

# 1. 下载并安装 clash-meta 核心
echo -e "${GREEN}[1/4] 下载 Clash Meta...${NC}"
CLASHC_FILE="clashc-linux-${ARCH_SUFFIX}-${CLASHC_VERSION}.gz"
DOWNLOAD_URL="${DOWNLOAD_BASE}/bin/${CLASHC_FILE}"
TEMP_DIR=$(mktemp -d)
TEMP_FILE="$TEMP_DIR/$CLASHC_FILE"

echo "下载地址: $DOWNLOAD_URL"
if wget -q --show-progress -O "$TEMP_FILE" "$DOWNLOAD_URL" 2>&1 || curl -fL --progress-bar -o "$TEMP_FILE" "$DOWNLOAD_URL"; then
    echo -e "${GREEN}✓ 下载成功${NC}"
else
    echo -e "${RED}✗ 下载失败${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo -e "${GREEN}[2/4] 解压并安装...${NC}"
gunzip -f "$TEMP_FILE"
CLASHC_BIN="$TEMP_DIR/clashc-linux-${ARCH_SUFFIX}-${CLASHC_VERSION}"
sudo mv "$CLASHC_BIN" /usr/local/bin/clash-meta
sudo chmod +x /usr/local/bin/clash-meta
sudo ln -sf /usr/local/bin/clash-meta /usr/local/bin/clash
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✓ 安装完成${NC}"
echo ""

# 2. 配置 Clash Meta
echo -e "${GREEN}[3/4] 配置 Clash Meta...${NC}"
mkdir -p ~/.config/clashc

CONFIG_URL="${DOWNLOAD_BASE}/data/config.yaml.example"
if [ -f ~/.config/clashc/config.yaml ]; then
    echo -e "${YELLOW}配置文件已存在，跳过下载${NC}"
else
    if wget -q -O ~/.config/clashc/config.yaml.example "$CONFIG_URL" 2>/dev/null; then
        echo -e "${GREEN}✓ 配置模板下载成功${NC}"
    fi
    echo -e "${YELLOW}请编辑配置文件: nano ~/.config/clashc/config.yaml${NC}"
fi

echo ""

# 3. 安装 GeoIP 数据库
echo -e "${GREEN}[4/4] 安装 GeoIP 数据库...${NC}"
GEOIP_URL="${DOWNLOAD_BASE}/data/geoip.dat"
GEOSITE_URL="${DOWNLOAD_BASE}/data/geosite.dat"

if wget -q -O ~/.config/clashc/geoip.dat "$GEOIP_URL" 2>/dev/null; then
    echo -e "${GREEN}✓ GeoIP.dat 下载成功${NC}"
fi

if wget -q -O ~/.config/clashc/geosite.dat "$GEOSITE_URL" 2>/dev/null; then
    echo -e "${GREEN}✓ GeoSite.dat 下载成功${NC}"
fi

echo ""
echo -e "${GREEN}=== 安装完成 ===${NC}"
echo ""
echo "管理命令："
echo "  clashc start   # 启动服务"
echo "  clashc stop    # 停止服务"
echo "  clashc status  # 查看状态"
echo ""
echo -e "${YELLOW}请先编辑配置文件填入节点信息: nano ~/.config/clashc/config.yaml${NC}"
echo ""