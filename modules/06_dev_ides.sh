#!/bin/bash

#
# 模块：安装开发 IDE (JetBrains Toolbox, VS Code, Zed)
#

set -e

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="${ASSETS_DIR:-$BASE_DIR/assets}"

# 辅助函数
have_cmd() {
    command -v "$1" &>/dev/null
}

# --- 1. JetBrains Toolbox ---
install_toolbox() {
    echo -e "\n>>> [1/3] 处理 JetBrains Toolbox..."

    if have_cmd jetbrains-toolbox; then
        echo "JetBrains Toolbox 已安装。"
    else
        echo "正在安装 JetBrains Toolbox (AUR)..."
        # 使用 paru 安装
        paru -S --noconfirm jetbrains-toolbox
    fi

    echo "提示：IDEA Community 请在脚本结束后，通过 Toolbox 手动安装。"
}

# --- 2. VS Code (Microsoft Official) ---
install_vscode() {
    echo -e "\n>>> [2/3] 处理 VS Code (Official Bin)..."

    # A. 安装软件
    if have_cmd code; then
        echo "VS Code 已安装。"
    else
        echo "正在安装 visual-studio-code-bin (AUR)..."
        paru -S --noconfirm visual-studio-code-bin
    fi

    # B. 恢复配置文件 (settings.json, keybindings.json 等)
    VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
    VSCODE_ASSETS="$ASSETS_DIR/vscode"

    if [ -d "$VSCODE_ASSETS" ]; then
        echo "正在恢复 VS Code 配置..."
        mkdir -p "$VSCODE_CONFIG_DIR"

        # 备份旧配置
        if [ -f "$VSCODE_CONFIG_DIR/settings.json" ]; then
            echo "备份旧配置到 $VSCODE_CONFIG_DIR/settings.json.bak..."
            mv "$VSCODE_CONFIG_DIR/settings.json" "$VSCODE_CONFIG_DIR/settings.json.bak" 2>/dev/null || true
            mv "$VSCODE_CONFIG_DIR/keybindings.json" "$VSCODE_CONFIG_DIR/keybindings.json.bak" 2>/dev/null || true
        fi

        # 复制新配置
        cp -r "$VSCODE_ASSETS/"* "$VSCODE_CONFIG_DIR/"
        echo "VS Code 配置文件已覆盖。"
    else
        echo "警告：未找到 assets/vscode 目录，跳过配置恢复。"
    fi

    # C. 自动安装插件
    EXTENSIONS_FILE="$VSCODE_ASSETS/extensions.txt"
    if [ -f "$EXTENSIONS_FILE" ]; then
        echo "正在安装 VS Code 插件列表..."
        # 逐行读取插件 ID 并安装
        while IFS= read -r ext || [[ -n "$ext" ]]; do
            # 跳过空行和注释
            if [[ -z "$ext" || "$ext" == \#* ]]; then continue; fi

            echo "安装插件: $ext ..."
            # --force 避免已安装报错，--install-extension 安装
            code --install-extension "$ext" --force >/dev/null 2>&1 || echo "  -> 安装失败: $ext"
        done < "$EXTENSIONS_FILE"
        echo "插件安装流程结束。"
    else
        echo "未找到 extensions.txt，跳过插件安装。"
    fi
}

# --- 3. Zed Editor ---
install_zed() {
    echo -e "\n>>> [3/3] 处理 Zed Editor..."

    # A. 安装软件
    if have_cmd zed; then
        echo "Zed 已安装。"
    else
        echo "正在安装 zed-preview-bin (AUR)..."
        paru -S --noconfirm zed-preview-bin
    fi

    # B. 恢复配置文件
    ZED_CONFIG_DIR="$HOME/.config/zed"
    ZED_ASSETS="$ASSETS_DIR/zed"

    if [ -d "$ZED_ASSETS" ]; then
        echo "正在恢复 Zed 配置..."
        mkdir -p "$ZED_CONFIG_DIR"

        # 备份整个旧目录
        if [ "$(ls -A $ZED_CONFIG_DIR 2>/dev/null)" ]; then
            echo "备份旧 Zed 配置..."
            mv "$ZED_CONFIG_DIR" "${ZED_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$ZED_CONFIG_DIR"
        fi

        # 复制新配置
        cp -r "$ZED_ASSETS/"* "$ZED_CONFIG_DIR/"
        echo "Zed 配置文件已恢复。"
    else
        echo "警告：未找到 assets/zed 目录，跳过配置恢复。"
    fi
}

main() {
    echo "=================================="
    echo "   开发 IDE 安装向导"
    echo "=================================="

    install_toolbox
    install_vscode
    install_zed

    echo ""
    echo "✅ 所有 IDE 处理完毕。"
    echo "   - VS Code: 已安装并尝试恢复插件。"
    echo "   - Zed: 已安装并恢复配置。"
    echo "   - IDEA: 请打开 JetBrains Toolbox 手动安装。"
}

main "$@"
