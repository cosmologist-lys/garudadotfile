#!/bin/bash

#
# 模块：配置 ArchLinuxCN 中国镜像源
#

set -e

PACMAN_CONF="/etc/pacman.conf"

# 检查包是否已安装的辅助函数
have_pkg() {
    pacman -Qi "$1" &>/dev/null
}


# 1. 添加仓库配置 (使用清华源确保数据库可同步)
ensure_archcn_repo() {
    if grep -q "^\[archlinuxcn\]" "$PACMAN_CONF"; then
        echo "archlinuxcn 仓库配置已存在。"
        return
    fi

    echo "添加 archlinuxcn 仓库 ..."
    sudo cp "$PACMAN_CONF" "$PACMAN_CONF.bak.$(date +%Y%m%d_%H%M%S)"

    # 直接写入清华源，避免首次连接失败
    sudo bash -c "cat >> '$PACMAN_CONF' <<'EOF'

[archlinuxcn]
Server = https://repo.archlinuxcn.org/\$arch
EOF"
}

# 2. 安装 Keyring (核心难点)
install_archcn_keyring() {
    if have_pkg archlinuxcn-keyring; then
        echo "archlinuxcn-keyring 已安装。"
        return
    fi

    echo "正在处理密钥环..."

    # [关键] 步骤 A: 初始化本地基础密钥 (解决 Unknown Trust)
    # 这一步是为了防止 pacman 连官方包的签名都不认
    sudo pacman-key --init
    sudo pacman-key --populate archlinux

    # 步骤 B: 刷新数据库
    echo "刷新数据库..."
    sudo pacman -Sy

    # 步骤 C: 安装 archlinuxcn-keyring
    echo "安装 archlinuxcn-keyring..."
    # 既然已经初始化了基础密钥，直接安装通常就能成功
    if ! sudo pacman -S --noconfirm archlinuxcn-keyring; then
        echo "⚠️  标准安装失败，尝试先接收密钥再安装..."
        # 备选方案：手动接收 farseerfc 等维护者的 key (这是 CN 源的 Master Key)
        # 但在脚本里硬编码 Key ID 不太好，我们尝试暴力方案：
        # 如果安装失败，提示用户可能需要手动介入
        echo -e "\033[0;31m错误：无法安装 keyring。请检查网络或尝试手动运行 'sudo pacman -S archlinuxcn-keyring'\033[0m"
        exit 1
    fi

    # [关键] 步骤 D: 导入 CN 源的密钥
    echo "导入 archlinuxcn 密钥..."
    sudo pacman-key --populate archlinuxcn
}

# 3. 切换到 Mirrorlist (负载均衡)
switch_to_mirrorlist() {
    echo "配置镜像列表..."

    # 1. 安装镜像列表包
    if ! have_pkg archlinuxcn-mirrorlist-git; then
        # 尝试安装 git 版或普通版
        sudo pacman -S --noconfirm archlinuxcn-mirrorlist-git || sudo pacman -S --noconfirm archlinuxcn-mirrorlist
    fi

    # 2. 检查文件是否存在
    if [ ! -f /etc/pacman.d/archlinuxcn-mirrorlist ]; then
        echo "⚠️  未找到 mirrorlist 文件，保留清华源单点配置。"
        return
    fi

    # 3. 启用所有镜像 (去注释)
    sudo sed -i 's/^# Server/Server/' /etc/pacman.d/archlinuxcn-mirrorlist

    # 4. 修改配置文件使用 Include
    if ! grep -q "Include = /etc/pacman.d/archlinuxcn-mirrorlist" "$PACMAN_CONF"; then
        sudo sed -i '/\[archlinuxcn\]/{n;s|Server = .*|Include = /etc/pacman.d/archlinuxcn-mirrorlist|}' "$PACMAN_CONF"
        echo "已切换至 mirrorlist 配置。"
    fi
}

main() {
    echo ">>> 开始配置 ArchLinuxCN 源..."
    ensure_archcn_repo
    install_archcn_keyring
    switch_to_mirrorlist

    echo ">>> ArchLinuxCN 配置完成。"
}

main "$@"
