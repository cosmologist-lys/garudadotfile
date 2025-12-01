#!/bin/bash

set -e

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="${ASSETS_DIR:-$BASE_DIR/assets}"

have_pkg() {
    pacman -Qi "$1" &>/dev/null
}

ensure_fcitx5_packages() {
    # 检查是否已安装主要包
    if have_pkg fcitx5; then
        echo "Fcitx5 已安装，跳过包安装。"
        return
    fi

    echo "安装 Fcitx5 及相关组件..."
    # fcitx5-im: 基础框架和输入法引擎
    # fcitx5-chinese-addons: 拼音等中文输入法
    # fcitx5-pinyin-zhwiki: 拼音词库（来自中文维基百科）
    # fcitx5-material-color: Material Design 主题
    sudo pacman -Syy --noconfirm \
        fcitx5-im \
        fcitx5-chinese-addons \
        fcitx5-pinyin-zhwiki \
        fcitx5-material-color
}

ensure_environment_variables() {
    # 为所有 Shell 和 GUI 应用配置输入法环境变量
    # 在 /etc/environment 中配置对所有会话都生效
    ENV_FILE="/etc/environment"

    echo "检查和配置输入法环境变量..."

    # 检查是否已配置
    if grep -q "GTK_IM_MODULE=fcitx" "$ENV_FILE" && \
       grep -q "QT_IM_MODULE=fcitx" "$ENV_FILE" && \
       grep -q "XMODIFIERS=@im=fcitx" "$ENV_FILE"; then
        echo "输入法环境变量已配置，跳过。"
        return
    fi

    # 备份原文件
    sudo cp "$ENV_FILE" "$ENV_FILE.bak.fcitx5" 2>/dev/null || true

    # 删除旧的 IM 模块配置（如果存在其他输入法的配置）
    sudo sed -i '/^GTK_IM_MODULE=/d' "$ENV_FILE" 2>/dev/null || true
    sudo sed -i '/^QT_IM_MODULE=/d' "$ENV_FILE" 2>/dev/null || true
    sudo sed -i '/^XMODIFIERS=/d' "$ENV_FILE" 2>/dev/null || true
    sudo sed -i '/^SDL_IM_MODULE=/d' "$ENV_FILE" 2>/dev/null || true

    # 追加 Fcitx5 的环境变量
    # 注意：Garuda 通常使用 Wayland，这些变量至关重要
    sudo bash -c "cat >> '$ENV_FILE' <<EOF
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
EOF"

    echo "输入法环境变量配置完成。"
}

ensure_fcitx5_autostart() {
    # Fcitx5 通过 XDG Autostart 机制启动，而不是 systemd 服务
    # 检查 autostart 文件是否存在
    local autostart_file="/etc/xdg/autostart/org.fcitx.Fcitx5.desktop"

    if [ -f "$autostart_file" ]; then
        echo "✓ Fcitx5 自动启动配置已存在"
        echo "  位置：$autostart_file"
    else
        echo "⚠ 警告：未找到 Fcitx5 自动启动文件"
        echo "  预期位置：$autostart_file"
        echo "  Fcitx5 可能需要手动启动"
    fi

    # 提示用户如何手动启动（如果需要）
    echo ""
    echo "提示：Fcitx5 会在重新登录后自动启动"
    echo "      如需立即启动，请运行：fcitx5 &"
}

main() {
    echo "=== 安装 Fcitx5 输入法 ==="
    ensure_fcitx5_packages

    echo ""
    echo "=== 配置环境变量 ==="
    ensure_environment_variables

    echo ""
    echo "=== 检查自动启动配置 ==="
    ensure_fcitx5_autostart

    echo ""
    echo "=========================================="
    echo "✓ Fcitx5 输入法配置完成！"
    echo "=========================================="
    echo ""
    echo "📝 重要提示："
    echo "  1. 环境变量已配置到 /etc/environment"
    echo "  2. 需要重新登录或重启系统才能生效"
    echo "  3. 重新登录后，Fcitx5 会自动启动"
    echo ""
    echo "🚀 立即测试（可选）："
    echo "  source /etc/environment && fcitx5 &"
    echo ""
    echo "⚙️  配置输入法："
    echo "  重新登录后运行：fcitx5-configtool"
}

main "$@"
