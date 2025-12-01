#!/bin/bash

set -e

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="${ASSETS_DIR:-$BASE_DIR/assets}"

have_pkg() {
    pacman -Qi "$1" &>/dev/null
}

ensure_v2ray_package() {
    if have_pkg v2ray; then
        echo "v2ray 已安装，跳过。"
    else
        echo "安装 v2ray..."
        sudo pacman -Syy --noconfirm v2ray
    fi
}

prompt_v2ray_config() {
    echo ""
    echo "=== V2Ray 配置信息 ==="
    echo "请输入 V2Ray 服务器配置信息："
    echo ""

    # 提示输入服务器地址
    read -p "请输入服务器地址 (server_addr): " SERVER_ADDR
    while [ -z "$SERVER_ADDR" ]; do
        echo "错误：服务器地址不能为空！"
        read -p "请输入服务器地址 (server_addr): " SERVER_ADDR
    done

    # 提示输入用户 ID
    read -p "请输入用户 ID (UUID): " USER_ID
    while [ -z "$USER_ID" ]; do
        echo "错误：用户 ID 不能为空！"
        read -p "请输入用户 ID (UUID): " USER_ID
    done

    echo ""
    echo "配置信息确认："
    echo "  服务器地址: $SERVER_ADDR"
    echo "  用户 ID: $USER_ID"
    echo ""
    read -p "确认以上信息正确？(y/n): " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "取消配置，请重新运行脚本。"
        exit 1
    fi
}

ensure_v2ray_config() {
    V2RAY_CONFIG="/etc/v2ray/config.json"

    # 如果配置文件已存在，询问是否覆盖
    if [ -f "$V2RAY_CONFIG" ]; then
        echo "V2Ray 配置文件已存在：$V2RAY_CONFIG"
        read -p "是否重新配置(如果是新安装的v2ray请输入y)？(y/n): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "跳过 V2Ray 配置。"
            return
        fi
    fi

    # 检查模板文件是否存在
    local template_file="$ASSETS_DIR/v2ray/config.json"
    if [ ! -f "$template_file" ]; then
        echo "错误：未找到配置模板文件：$template_file"
        echo "请确保 assets/v2ray/config.json 存在。"
        exit 1
    fi

    # 获取用户输入
    prompt_v2ray_config

    # 创建临时配置文件
    local temp_config="/tmp/v2ray_config_$$.json"

    echo "生成 V2Ray 配置文件..."

    # 使用 sed 替换占位符
    sed -e "s/server_addr/$SERVER_ADDR/g" \
        -e "s/\"id\": \"id\"/\"id\": \"$USER_ID\"/g" \
        "$template_file" > "$temp_config"

    # 验证生成的 JSON 是否有效（如果系统有 jq）
    if command -v jq >/dev/null 2>&1; then
        if ! jq empty "$temp_config" 2>/dev/null; then
            echo "警告：生成的配置文件 JSON 格式可能有误，但仍将继续部署。"
        else
            echo "配置文件 JSON 格式验证通过。"
        fi
    fi

    # 部署配置文件
    sudo mkdir -p /etc/v2ray
    sudo cp "$temp_config" "$V2RAY_CONFIG"
    sudo chmod 644 "$V2RAY_CONFIG"

    # 清理临时文件
    rm -f "$temp_config"

    echo "V2Ray 配置文件已部署到：$V2RAY_CONFIG"
}

ensure_proxy_scripts() {
    TARGET_DIR="$HOME/.config/shells"
    mkdir -p "$TARGET_DIR"

    # 检查代理脚本是否已部署
    if [ -f "$TARGET_DIR/proxy_on.fish" ] && [ -f "$TARGET_DIR/proxy_off.fish" ]; then
        echo "Fish 代理脚本已存在，跳过部署。"
        return
    fi

    local proxy_on="$ASSETS_DIR/v2ray/proxy_on.fish"
    local proxy_off="$ASSETS_DIR/v2ray/proxy_off.fish"

    if [ -f "$proxy_on" ] && [ -f "$proxy_off" ]; then
        echo "部署 Fish 代理控制脚本到 $TARGET_DIR..."
        cp "$proxy_on" "$TARGET_DIR/"
        cp "$proxy_off" "$TARGET_DIR/"
        chmod +x "$TARGET_DIR/proxy_on.fish" "$TARGET_DIR/proxy_off.fish"
    else
        echo "警告：未在 assets/v2ray 中找到 proxy_on.fish 或 proxy_off.fish。"
        echo "      预期路径："
        echo "        - $proxy_on"
        echo "        - $proxy_off"
    fi
}

ensure_fish_aliases() {
    FISH_CONFIG="$HOME/.config/fish/config.fish"
    mkdir -p "$(dirname "$FISH_CONFIG")"

    # 创建文件如果不存在
    touch "$FISH_CONFIG"

    # 检查别名是否已添加
    if grep -q "alias ton" "$FISH_CONFIG"; then
        echo "Fish 代理别名已存在，跳过。"
        return
    fi

    TARGET_DIR="$HOME/.config/shells"

    echo "向 config.fish 添加代理别名..."
    cat >> "$FISH_CONFIG" <<EOF

# --- V2Ray Proxy Aliases ---
alias ton='source $TARGET_DIR/proxy_on.fish'
alias tof='source $TARGET_DIR/proxy_off.fish'
EOF
}

main() {
    ensure_v2ray_package
    ensure_v2ray_config
    ensure_proxy_scripts
    ensure_fish_aliases

    echo ""
    echo "V2Ray 模块配置完成。"
    echo ""
    echo "使用方法："
    echo "  - 启动 V2Ray: sudo systemctl start v2ray"
    echo "  - 开机自启: sudo systemctl enable v2ray"
    echo "  - 开启代理: ton"
    echo "  - 关闭代理: tof"
}

main "$@"
