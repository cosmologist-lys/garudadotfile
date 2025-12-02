#!/bin/bash

#
# 模块：安装开发环境 (Java, Rust, Python, uv, SVN)
# 包含交互式菜单
#

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fish 配置文件路径
FISH_CONFIG="$HOME/.config/fish/config.fish"

# 辅助函数：检查命令是否存在
have_cmd() {
    command -v "$1" &>/dev/null
}

# --- 1. 安装 Java (11 & 21) ---
install_java() {
    echo -e "\n${BLUE}>>> [1/5] 检查 Java 环境...${NC}"

    # 检查是否已安装特定版本
    if pacman -Qi jdk11-openjdk &>/dev/null && pacman -Qi jdk21-openjdk &>/dev/null; then
        echo "Java 11 和 Java 21 已安装。"
    else
        echo "正在安装 JDK 11 和 JDK 21..."
        sudo pacman -S --noconfirm jdk11-openjdk jdk21-openjdk
    fi

    # 设置默认版本为 21 (你可以根据喜好修改)
    echo "设置 JDK 21 为默认版本..."
    if command -v archlinux-java &>/dev/null; then
        sudo archlinux-java set java-21-openjdk
        echo "当前 Java 版本："
        java -version | head -n 1
    fi
}

# --- 2. 安装 Rust (使用 rsproxy 镜像) ---
install_rust() {
    echo -e "\n${BLUE}>>> [2/5] 检查 Rust 环境...${NC}"

    if have_cmd cargo; then
        echo "Rust (Cargo) 已安装，跳过。"
    else
        echo "准备安装 Rust (通过 rsproxy.cn 加速)..."

        # 1. 设置当前会话变量 (供 rustup-init 使用)
        export RUSTUP_DIST_SERVER="https://rsproxy.cn"
        export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"

        # 2. 静默安装 Rustup
        # -y: 自动确认
        # --no-modify-path: 我们稍后手动配置 Fish，不让它乱改 Bash 配置
        curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y --no-modify-path

        # 3. 配置 Fish 环境变量 (持久化)
        echo "配置 Fish Shell 环境变量..."
        mkdir -p "$(dirname "$FISH_CONFIG")"

        # 写入 Path 和 Mirror 变量到 config.fish
        if ! grep -q "RUSTUP_DIST_SERVER" "$FISH_CONFIG"; then
            cat >> "$FISH_CONFIG" <<EOF

# --- Rust Environment (rsproxy) ---
set -gx RUSTUP_DIST_SERVER "https://rsproxy.cn"
set -gx RUSTUP_UPDATE_ROOT "https://rsproxy.cn/rustup"
fish_add_path "\$HOME/.cargo/bin"
EOF
            echo "已将 Rust 环境变量写入 $FISH_CONFIG"
        fi

        # 4. 配置 Cargo 镜像源 (crates.io)
        echo "配置 Cargo 镜像源..."
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
        echo "Cargo config.toml 配置完成。"
    fi
}

# --- 3. 安装 Python ---
install_python() {
    echo -e "\n${BLUE}>>> [3/5] 检查 Python 环境...${NC}"
    if have_cmd python; then
        echo "Python 已安装: $(python --version)"
    else
        echo "安装 Python..."
        sudo pacman -S --noconfirm python
    fi
}

# --- 4. 安装 uv (Python 包管理器) ---
install_uv() {
    echo -e "\n${BLUE}>>> [4/5] 检查 uv 环境...${NC}"
    if have_cmd uv; then
        echo "uv 已安装: $(uv --version)"
    else
        echo "安装 uv (via Pacman)..."
        # 优先使用 pacman 安装二进制包，速度快
        sudo pacman -S --noconfirm uv
    fi
}

# --- 5. 安装 SVN ---
install_svn() {
    echo -e "\n${BLUE}>>> [5/5] 检查 SVN 环境...${NC}"
    if have_cmd svn; then
        echo "SVN 已安装: $(svn --version --quiet)"
    else
        echo "安装 Subversion..."
        sudo pacman -S --noconfirm subversion
    fi
}

# --- 菜单逻辑 ---
show_menu() {
    echo ""
    echo "=================================="
    echo "   开发环境安装向导"
    echo "=================================="
    echo "1. Java (JDK 11 & 21)"
    echo "2. Rust (rsproxy 源)"
    echo "3. Python (System)"
    echo "4. uv (Python Manager)"
    echo "5. SVN (Subversion)"
    echo "----------------------------------"
    echo "0. 安装所有 (Install All)"
    echo "q. 退出 (Quit)"
    echo "=================================="
    echo ""
    read -p "请输入选项 [0-5]: " choice
}

main() {
    show_menu

    case "$choice" in
        1) install_java ;;
        2) install_rust ;;
        3) install_python ;;
        4) install_uv ;;
        5) install_svn ;;
        0)
            install_java
            install_rust
            install_python
            install_uv
            install_svn
            ;;
        q|Q)
            echo "退出安装。"
            exit 0
            ;;
        *)
            echo "无效选项，退出。"
            exit 1
            ;;
    esac

    echo -e "\n${GREEN}>>> 选定任务执行完毕。${NC}"
    if [ "$choice" == "2" ] || [ "$choice" == "0" ]; then
        echo "提示：如果你刚刚安装了 Rust，请重新打开终端或执行 'source ~/.config/fish/config.fish' 以加载环境变量。"
    fi
}

main "$@"
