#!/bin/bash
# CEC Tools 主安装脚本
# 用法: curl -fsSL http://tools.cec.cc:8410/tools/install.sh | bash
# 或: curl -fsSL http://localhost:8410/tools/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CEC Tools - 服务器翻墙工具一键安装${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 自动检测下载源
SCRIPT_SOURCE="${BASH_SOURCE[0]}"

if [[ "$SCRIPT_SOURCE" == *"tools.cec.cc"* ]]; then
    DOWNLOAD_BASE="http://tools.cec.cc:8410/tools"
elif [[ "$SCRIPT_SOURCE" == *"localhost"* ]] || [[ "$SCRIPT_SOURCE" == *"127.0.0.1"* ]]; then
    DOWNLOAD_BASE="http://localhost:8410/tools"
else
    DOWNLOAD_BASE="http://tools.cec.cc:8410/tools"
fi

echo -e "${BLUE}下载源: ${GREEN}$DOWNLOAD_BASE${NC}"
echo ""

# 检测参数
INSTALL_MODE="${1:-menu}"

# 显示菜单
show_menu() {
    echo -e "${BLUE}请选择要安装的工具：${NC}"
    echo ""
    echo "  1) ${GREEN}Clash Meta${NC}  - TUN透明代理，智能分流"
    echo "  2) ${GREEN}V2Ray${NC}        - VMess协议，多种传输方式"
    echo "  3) ${GREEN}全部安装${NC}     - 安装所有工具"
    echo "  4) ${YELLOW}退出${NC}"
    echo ""
    read -p "请输入选项 [1-4]: " -n 1 -r choice
    echo ""
    echo ""
}

# 安装 Clash Meta
install_clash() {
    echo -e "${BLUE}开始安装 Clash Meta...${NC}"
    echo ""

    if curl -fsSL "$DOWNLOAD_BASE/clash/install.sh" | bash; then
        echo ""
        echo -e "${GREEN}✓ Clash Meta 安装成功${NC}"
        return 0
    else
        echo -e "${RED}✗ Clash Meta 安装失败${NC}"
        return 1
    fi
}

# 安装 V2Ray
install_v2ray() {
    echo -e "${BLUE}开始安装 V2Ray...${NC}"
    echo ""

    if curl -fsSL "$DOWNLOAD_BASE/v2ray/install.sh" | bash; then
        echo ""
        echo -e "${GREEN}✓ V2Ray 安装成功${NC}"
        return 0
    else
        echo -e "${RED}✗ V2Ray 安装失败${NC}"
        return 1
    fi
}

# 主逻辑
case "$INSTALL_MODE" in
    clash)
        install_clash
        ;;
    v2ray)
        install_v2ray
        ;;
    all)
        install_clash && install_v2ray
        ;;
    menu|*)
        show_menu

        case "$choice" in
            1)
                install_clash
                ;;
            2)
                install_v2ray
                ;;
            3)
                install_clash
                echo ""
                install_v2ray
                ;;
            4|*)
                echo -e "${YELLOW}已取消安装${NC}"
                exit 0
                ;;
        esac
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}提示：${NC}"
echo "  • 查看帮助: clashc help 或 v2rayc help"
echo "  • 配置文件位置: ~/.config/clashc/ 或 ~/.config/v2ray/"
echo ""