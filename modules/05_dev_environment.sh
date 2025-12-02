#!/bin/bash

#
# 模块：安装开发环境 (Java, Rust, Python, uv, SVN)
# 包含交互式菜单
#

set -e

# --- 颜色定义 (从 setup.sh 继承) ---
GREEN=${GREEN:-\033[0;32m}
BLUE=${BLUE:-\033[0;34m}
RED=${RED:-\033[0;31m}
YELLOW=${YELLOW:-\033[1;33m}
NC=${NC:-\033[0m}

# Fish 配置文件路径
FISH_CONFIG="$HOME/.config/fish/config.fish"

# 辅助函数：检查命令是否存在
have_cmd() {
    command -v "$1" &>/dev/null
}

# --- 1. 安装 Java (11 & 21) ---
install_java() {
    echo -e "\n${BLUE}>>> [2/5] 检查 Java 环境...${NC}"

    # 检查是否已安装特定版本
    if pacman -Qi jdk11-openjdk &>/dev/null && pacman -Qi jdk21-openjdk &>/dev/null; then
        echo -e "${YELLOW}Java 11 和 Java 21 已安装。${NC}"
    else
        echo -e "${BLUE}正在安装 JDK 11 和 JDK 21...${NC}"
        sudo pacman -S --noconfirm jdk11-openjdk jdk21-openjdk
    fi

    # 设置默认版本为 21 (你可以根据喜好修改)
    echo -e "${BLUE}设置 JDK 21 为默认版本...${NC}"
    if command -v archlinux-java &>/dev/null; then
        sudo archlinux-java set java-21-openjdk
        echo -e "${GREEN}当前 Java 版本：${NC}"
        java -version | head -n 1
    fi
}

# --- 2. 安装 Rust (使用 rsproxy 镜像) ---
install_rust() {
    echo -e "\n${BLUE}>>> [1/5] 检查 Rust 环境...${NC}"

    if have_cmd cargo; then
        echo -e "${YELLOW}Rust (Cargo) 已安装，跳过。${NC}"
    else
        echo -e "${BLUE}准备安装 Rust (通过 rsproxy.cn 加速)...${NC}"

        # 1. 设置当前会话变量 (供 rustup-init 使用)
        export RUSTUP_DIST_SERVER="https://rsproxy.cn"
        export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"

        # 2. 静默安装 Rustup
        # -y: 自动确认
        # --no-modify-path: 我们稍后手动配置 Fish，不让它乱改 Bash 配置
        curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y --no-modify-path

        # 3. 配置 Fish 环境变量 (持久化)
        echo -e "${BLUE}配置 Fish Shell 环境变量...${NC}"
        mkdir -p "$(dirname "$FISH_CONFIG")"

        # 写入 Path 和 Mirror 变量到 config.fish
        if ! grep -q "RUSTUP_DIST_SERVER" "$FISH_CONFIG"; then
            cat >> "$FISH_CONFIG" <<EOF

# --- Rust Environment (rsproxy) ---
set -gx RUSTUP_DIST_SERVER "https://rsproxy.cn"
set -gx RUSTUP_UPDATE_ROOT "https://rsproxy.cn/rustup"
fish_add_path "\$HOME/.cargo/bin"
EOF
            echo -e "${GREEN}已将 Rust 环境变量写入 $FISH_CONFIG${NC}"
        fi

        # 4. 配置 Cargo 镜像源 (crates.io)
        echo -e "${BLUE}配置 Cargo 镜像源...${NC}"
        mkdir -p "$HOME/.cargo"
        cat > "$HOME/.cargo/config.toml" <<EOF
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
EOF
        echo -e "${GREEN}Cargo config.toml 配置完成。${NC}"
    fi
}

# --- 3. 安装 Python ---
install_python() {
    echo -e "\n${BLUE}>>> [3/5] 检查 Python 环境...${NC}"
    if have_cmd python; then
        echo -e "${YELLOW}Python 已安装: $(python --version)${NC}"
    else
        echo -e "${BLUE}安装 Python...${NC}"
        sudo pacman -S --noconfirm python
    fi
}

# --- 4. 安装 uv (Python 包管理器) ---
install_uv() {
    echo -e "\n${BLUE}>>> [4/5] 检查 uv 环境...${NC}"
    if have_cmd uv; then
        echo -e "${YELLOW}uv 已安装: $(uv --version)${NC}"
    else
        echo -e "${BLUE}安装 uv (via Pacman)...${NC}"
        # 优先使用 pacman 安装二进制包，速度快
        sudo pacman -S --noconfirm uv
    fi
}

# --- 5. 安装 SVN ---
install_svn() {
    echo -e "\n${BLUE}>>> [5/5] 检查 SVN 环境...${NC}"
    if have_cmd svn; then
        echo -e "${YELLOW}SVN 已安装: $(svn --version --quiet)${NC}"
    else
        echo -e "${BLUE}安装 Subversion...${NC}"
        sudo pacman -S --noconfirm subversion
    fi
}

# --- 菜单逻辑 ---
show_menu() {
    echo ""
    echo -e "${BLUE}==================================${NC}"
    echo -e "   ${YELLOW}开发环境安装向导${NC}"
    echo -e "${BLUE}==================================${NC}"
    echo "1. Java (JDK 11 & 21)"
    echo "2. Rust (rsproxy 源)"
    echo "3. Python (System)"
    echo "4. uv (Python Manager)"
    echo "5. SVN (Subversion)"
    echo "----------------------------------"
    echo "0. 安装所有 (Install All)"
    echo "q. 退出 (Quit)"
    echo -e "${BLUE}==================================${NC}"
    echo ""
    read -p "请输入选项 [0-5]: " choice
}

main() {
    #show_menu

    install_rust
    install_java
    install_python
    install_uv
    install_svn

    echo -e "\n${GREEN}>>> 选定任务执行完毕。${NC}"
    if [ "$choice" == "2" ] || [ "$choice" == "0" ]; then
        echo -e "${YELLOW}提示：如果你刚刚安装了 Rust，请重新打开终端或执行 'source ~/.config/fish/config.fish' 以加载环境变量。${NC}"
    fi
}

main "$@"
