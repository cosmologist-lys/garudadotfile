#!/bin/bash

#
# 模块：配置 makepkg 使用 aria2 加速 (支持动态代理)
#

set -e

# --- 颜色定义 (从 setup.sh 继承) ---
GREEN=${GREEN:-\033[0;32m}
BLUE=${BLUE:-\033[0;34m}
RED=${RED:-\033[0;31m}
YELLOW=${YELLOW:-\033[1;33m}
NC=${NC:-\033[0m}

MAKEPKG_CONF="/etc/makepkg.conf"

have_pkg() {
    pacman -Qi "$1" &>/dev/null
}

install_aria2() {
    if have_pkg aria2; then
        echo -e "${YELLOW}aria2 已安装。${NC}"
    else
        echo -e "${BLUE}安装 aria2...${NC}"
        sudo pacman -S --noconfirm aria2
    fi
}

configure_makepkg() {
    echo -e "${BLUE}修改 makepkg.conf 配置...${NC}"

    # 1. 备份
    sudo cp "$MAKEPKG_CONF" "$MAKEPKG_CONF.bak.$(date +%Y%m%d_%H%M%S)"

    # 定义 aria2c 命令
    # [关键修改]：去掉了 --all-proxy 参数
    # aria2c 会自动读取 shell 环境中的 http_proxy/https_proxy 变量
    # 降低并发数到 4 以避免被源站封禁
    local aria2_cmd="/usr/bin/aria2c --allow-overwrite=true --continue=true --file-allocation=none --log-level=error --max-connection-per-server=4 --max-tries=3 --retry-wait=3 --split=4 --summary-interval=0 -o %o %u"

    # 2. 使用 sed 替换
    # 逻辑：查找以 'http:: 或 'https:: 开头的行，替换为新的命令

    echo -e "${BLUE}配置 HTTP/HTTPS 下载代理 (动态环境)...${NC}"

    # 替换 HTTP
    sudo sed -i "s|'http::/usr/bin/curl .* -o %o %u'|'http::${aria2_cmd}'|g" "$MAKEPKG_CONF"
    # 如果已经是 aria2c 了，也更新一下参数（移除硬编码代理）
    sudo sed -i "s|'http::/usr/bin/aria2c .* -o %o %u'|'http::${aria2_cmd}'|g" "$MAKEPKG_CONF"

    # 替换 HTTPS
    sudo sed -i "s|'https::/usr/bin/curl .* -o %o %u'|'https::${aria2_cmd}'|g" "$MAKEPKG_CONF"
    sudo sed -i "s|'https::/usr/bin/aria2c .* -o %o %u'|'https::${aria2_cmd}'|g" "$MAKEPKG_CONF"

    echo -e "${GREEN}makepkg.conf 已更新。${NC}"
}

main() {
    echo -e "${BLUE}>>> 开始配置 Paru/Makepkg 下载加速...${NC}"

    install_aria2
    configure_makepkg

    echo -e "${GREEN}>>> 配置完成。${NC}"
    echo -e "    ${YELLOW}现在 paru 将根据当前的 Shell 环境变量决定是否走代理(若已执行脚本安装v2ray)。${NC}"
    echo -e "    ${YELLOW}开启代理: ton -> paru -S xxx (走代理)${NC}"
    echo -e "    ${YELLOW}关闭代理: tof -> paru -S xxx (直连)${NC}"
}

main "$@"
