#!/bin/bash

#
# 模块：安装开发 IDE (JetBrains Toolbox, VS Code, Zed)
#

set -e

# --- 颜色定义 (从 setup.sh 继承) ---
GREEN=${GREEN:-\\033[0;32m}
BLUE=${BLUE:-\\033[0;34m}
RED=${RED:-\\033[0;31m}
YELLOW=${YELLOW:-\\033[1;33m}
NC=${NC:-\\033[0m}

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
    echo -e "\n${BLUE}>>> [1/3] 处理 JetBrains Toolbox...${NC}"

    if have_cmd jetbrains-toolbox; then
        echo -e "${YELLOW}JetBrains Toolbox 已安装。${NC}"
    else
        echo -e "${BLUE}正在安装 JetBrains Toolbox (AUR)...${NC}"
        # 使用 paru 安装
        paru -S --noconfirm jetbrains-toolbox
    fi

    echo -e "${YELLOW}提示：IDEA Community 请在脚本结束后，通过 Toolbox 手动安装。${NC}"
}

# --- 2. VS Code (Microsoft Official) ---
install_vscode() {
    echo -e "\n${BLUE}>>> [2/3] 处理 VS Code (Official Bin)...${NC}"

    # A. 安装软件
    if have_cmd code; then
        echo -e "${YELLOW}VS Code 已安装。${NC}"
    else
        echo -e "${BLUE}正在安装 visual-studio-code-bin (AUR)...${NC}"
        paru -S --noconfirm visual-studio-code-bin
    fi

    # B. 恢复配置文件 (settings.json, keybindings.json 等)
    VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
    VSCODE_ASSETS="$ASSETS_DIR/vscode"

    if [ -d "$VSCODE_ASSETS" ]; then
        echo -e "${BLUE}正在恢复 VS Code 配置...${NC}"
        mkdir -p "$VSCODE_CONFIG_DIR"

        # 备份旧配置
        if [ -f "$VSCODE_CONFIG_DIR/settings.json" ]; then
            echo -e "${YELLOW}备份旧配置到 $VSCODE_CONFIG_DIR/settings.json.bak...${NC}"
            mv "$VSCODE_CONFIG_DIR/settings.json" "$VSCODE_CONFIG_DIR/settings.json.bak" 2>/dev/null || true
            mv "$VSCODE_CONFIG_DIR/keybindings.json" "$VSCODE_CONFIG_DIR/keybindings.json.bak" 2>/dev/null || true
        fi

        # 复制新配置
        cp -r "$VSCODE_ASSETS/"* "$VSCODE_CONFIG_DIR/"
        echo -e "${GREEN}VS Code 配置文件已覆盖。${NC}"
    else
        echo -e "${YELLOW}警告：未找到 assets/vscode 目录，跳过配置恢复。${NC}"
    fi

    # C. 自动安装插件
    EXTENSIONS_FILE="$VSCODE_ASSETS/extensions.txt"
    if [ -f "$EXTENSIONS_FILE" ]; then
        echo -e "${BLUE}正在安装 VS Code 插件列表...${NC}"
        # 逐行读取插件 ID 并安装
        while IFS= read -r ext || [[ -n "$ext" ]]; do
            # 跳过空行和注释
            if [[ -z "$ext" || "$ext" == \#* ]]; then continue; fi

            echo -e "${BLUE}安装插件: $ext ...${NC}"
            # --force 避免已安装报错，--install-extension 安装
            code --install-extension "$ext" --force >/dev/null 2>&1 || echo -e "  ${RED}-> 安装失败: $ext${NC}"
        done < "$EXTENSIONS_FILE"
        echo -e "${GREEN}插件安装流程结束。${NC}"
    else
        echo -e "${YELLOW}未找到 extensions.txt，跳过插件安装。${NC}"
    fi
}

# --- 3. Zed Editor ---
install_zed() {
    echo -e "\n${BLUE}>>> [3/3] 处理 Zed Editor...${NC}"

    # A. 安装软件
    if have_cmd zed; then
        echo -e "${YELLOW}Zed 已安装。${NC}"
    else
        echo -e "${BLUE}正在安装 zed-preview-bin (AUR)...${NC}"
        paru -S --noconfirm zed-preview-bin
    fi

    # B. 恢复配置文件
    ZED_CONFIG_DIR="$HOME/.config/zed"
    ZED_ASSETS="$ASSETS_DIR/zed"

    if [ -d "$ZED_ASSETS" ]; then
        echo -e "${BLUE}正在恢复 Zed 配置...${NC}"
        mkdir -p "$ZED_CONFIG_DIR"

        # 备份整个旧目录
        if [ "$(ls -A $ZED_CONFIG_DIR 2>/dev/null)" ]; then
            echo -e "${YELLOW}备份旧 Zed 配置...${NC}"
            mv "$ZED_CONFIG_DIR" "${ZED_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$ZED_CONFIG_DIR"
        fi

        # 复制新配置
        cp -r "$ZED_ASSETS/"* "$ZED_CONFIG_DIR/"
        echo -e "${GREEN}Zed 配置文件已恢复。${NC}"
    else
        echo -e "${YELLOW}警告：未找到 assets/zed 目录，跳过配置恢复。${NC}"
    fi
}

main() {
    echo -e "${BLUE}==================================${NC}"
    echo -e "   ${YELLOW}开发 IDE 安装向导${NC}"
    echo -e "${BLUE}==================================${NC}"

    install_toolbox
    install_vscode
    install_zed

    echo ""
    echo -e "${GREEN}✅ 所有 IDE 处理完毕。${NC}"
    echo -e "   - ${GREEN}VS Code:${NC} 已安装并尝试恢复插件。"
    echo -e "   - ${GREEN}Zed:${NC} 已安装并恢复配置。"
    echo -e "   - ${YELLOW}IDEA:${NC} 请打开 JetBrains Toolbox 手动安装。"
}

main "$@"
