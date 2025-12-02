#!/bin/bash

#
# 模块：配置 ArchLinuxCN 中国镜像源
#

set -e

# --- 颜色定义 (从 setup.sh 继承) ---
GREEN=${GREEN:-\033[0;32m}
BLUE=${BLUE:-\033[0;34m}
RED=${RED:-\033[0;31m}
YELLOW=${YELLOW:-\033[1;33m}
NC=${NC:-\033[0m}

PACMAN_CONF="/etc/pacman.conf"

# 检查包是否已安装的辅助函数
have_pkg() {
    pacman -Qi "$1" &>/dev/null
}


# 1. 添加仓库配置 (使用清华源确保数据库可同步)
ensure_archcn_repo() {
    if grep -q "^\[archlinuxcn\]" "$PACMAN_CONF"; then
        echo -e "${YELLOW}archlinuxcn 仓库配置已存在。${NC}"
        return
    fi

    echo -e "${BLUE}添加 archlinuxcn 仓库 ...${NC}"
    sudo cp "$PACMAN_CONF" "$PACMAN_CONF.bak.$(date +%Y%m%d_%H%M%S)"

    # 直接写入清华源，避免首次连接失败
    sudo bash -c "cat >> '$PACMAN_CONF' <<'EOF'

[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF"
}

# 2. 安装 Keyring (核心难点)
install_archcn_keyring() {
    if have_pkg archlinuxcn-keyring; then
        echo -e "${YELLOW}archlinuxcn-keyring 已安装。${NC}"
        return
    fi

    echo -e "${BLUE}正在处理密钥环...${NC}"

    # [关键] 步骤 A: 初始化本地基础密钥 (解决 Unknown Trust)
    # 这一步是为了防止 pacman 连官方包的签名都不认
    sudo pacman-key --init
    sudo pacman-key --populate archlinux

    # 步骤 B: 刷新数据库
    echo -e "${BLUE}刷新数据库...${NC}"
    sudo pacman -Sy

    # 步骤 C: 安装 archlinuxcn-keyring
    echo -e "${BLUE}安装 archlinuxcn-keyring...${NC}"
    # 既然已经初始化了基础密钥，直接安装通常就能成功
    if ! sudo pacman -S --noconfirm archlinuxcn-keyring; then
        echo -e "${YELLOW}⚠️  标准安装失败，尝试先接收密钥再安装...${NC}"
        # 备选方案：手动接收 farseerfc 等维护者的 key (这是 CN 源的 Master Key)
        # 但在脚本里硬编码 Key ID 不太好，我们尝试暴力方案：
        # 如果安装失败，提示用户可能需要手动介入
        echo -e "${RED}错误：无法安装 keyring。请检查网络或尝试手动运行 'sudo pacman -S archlinuxcn-keyring'${NC}"
        exit 1
    fi

    # [关键] 步骤 D: 导入 CN 源的密钥
    echo -e "${BLUE}导入 archlinuxcn 密钥...${NC}"
    sudo pacman-key --populate archlinuxcn
}

# 3. 切换到 Mirrorlist (负载均衡)
switch_to_mirrorlist() {
    echo -e "${BLUE}配置镜像列表...${NC}"

    # 1. 安装镜像列表包
    if ! have_pkg archlinuxcn-mirrorlist-git; then
        # 尝试安装 git 版或普通版
        sudo pacman -S --noconfirm archlinuxcn-mirrorlist-git || sudo pacman -S --noconfirm archlinuxcn-mirrorlist
    fi

    # 2. 检查文件是否存在
    if [ ! -f /etc/pacman.d/archlinuxcn-mirrorlist ]; then
        echo -e "${YELLOW}⚠️  未找到 mirrorlist 文件，保留清华源单点配置。${NC}"
        return
    fi

    # 3. 启用所有镜像 (去注释)
    sudo sed -i 's/^# Server/Server/' /etc/pacman.d/archlinuxcn-mirrorlist

    # 4. 修改配置文件使用 Include
    if ! grep -q "Include = /etc/pacman.d/archlinuxcn-mirrorlist" "$PACMAN_CONF"; then
        sudo sed -i '/\[archlinuxcn\]/{n;s|Server = .*|Include = /etc/pacman.d/archlinuxcn-mirrorlist|}' "$PACMAN_CONF"
        echo -e "${GREEN}已切换至 mirrorlist 配置。${NC}"
    fi
}

# 4. [新增] 确保 Fish Shell 已安装并设为默认
ensure_fish_shell() {
    echo -e "${BLUE}>>> 检查 Shell 环境 (Fish)...${NC}"

    # 4.1 安装 Fish
    if have_pkg fish; then
        echo -e "${YELLOW}Fish Shell 已安装。${NC}"
    else
        echo -e "${BLUE}正在安装 Fish Shell...${NC}"
        sudo pacman -S --noconfirm fish
    fi

    # 4.2 设置为默认 Shell
    # 获取 fish 的绝对路径
    FISH_PATH=$(command -v fish)

    # 获取当前用户的默认 Shell (从 /etc/passwd 读取)
    # 注意：$USER 是当前执行脚本的用户
    CURRENT_SHELL=$(grep "^$USER:" /etc/passwd | cut -d: -f7)

    if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
        echo -e "${BLUE}正在将默认 Shell 更改为 Fish...${NC}"

        # 使用 sudo chsh 可以避免密码交互，直接修改指定用户的 shell
        if sudo chsh -s "$FISH_PATH" "$USER"; then
            echo -e "${GREEN}默认 Shell 已更新为 Fish (下次登录生效)。${NC}"
        else
            echo -e "${RED}自动更改 Shell 失败，请稍后手动执行: chsh -s $FISH_PATH${NC}"
        fi
    else
        echo -e "${GREEN}当前默认 Shell 已是 Fish，无需更改。${NC}"
    fi
}

main() {
    echo -e "${BLUE}>>> 开始配置 ArchLinuxCN 源...${NC}"
    ensure_archcn_repo
    install_archcn_keyring
    switch_to_mirrorlist
    echo -e "${GREEN}>>> ArchLinuxCN 配置完成。${NC}"
    echo -e "${BLUE}>>> 开始配置基础 Shell(Fish)...${NC}"
    ensure_fish_shell
    echo -e "${GREEN}>>> Shell(Fish) 配置完成。${NC}"
}

main "$@"
