#!/bin/bash

#
# 模块：安装常用 GUI 应用与 CLI 工具 (交互式菜单)
#

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FISH_CONFIG="$HOME/.config/fish/config.fish"

# 定义软件列表 (格式: "显示名称|包名")
APPS_DATA=(
    "LibreOffice Fresh (办公套件)|libreoffice-fresh"
    "WeChat Universal (微信 - 推荐)|wechat-universal-bwrap"
    "Notion (笔记)|notion-app-electron"
    "Steam (游戏平台)|steam"
    "KCalc (计算器)|kcalc"
    "FileZilla (FTP/SFTP)|filezilla"
    "Remmina (远程桌面)|remmina"
    "Kate (高级文本编辑器)|kate"
    "Flameshot (截图工具)|flameshot"
    "Timeshift (系统备份)|timeshift"
    "Btop (资源监控 - C++)|btop"
    "Bottom (资源监控 - Rust)|bottom"
    "Bat (带高亮的 cat)|bat"
    "Eza (ls 的现代化替代)|eza"
    "Tree (目录树查看)|tree"
    "Fzf (模糊搜索神器)|fzf"
    "Zoxide (智能目录跳转)|zoxide"
    "Tldr (精简版 Man 手册 - Rust版)|tealdeer"
)

# 初始化状态数组 (1=选中, 0=未选中)
# 默认全选
declare -a SELECTED_STATUS
for ((i=0; i<${#APPS_DATA[@]}; i++)); do
    SELECTED_STATUS[$i]=1
done

# 辅助函数：显示菜单
show_menu() {
    clear
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}   常用应用安装列表 (Garuda/Arch)   ${NC}"
    echo -e "${BLUE}   注意以下应用需要安装Fish   ${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo "说明: 输入数字切换选中状态 (支持多个，如 '1 5 7')"
    echo "      输入 'a' 全选, 'n' 全不选"
    echo "      直接回车 (Enter) 开始安装"
    echo "------------------------------------------"

    for ((i=0; i<${#APPS_DATA[@]}; i++)); do
        IFS='|' read -r name pkg <<< "${APPS_DATA[$i]}"
        if [ "${SELECTED_STATUS[$i]}" -eq 1 ]; then
            echo -e "${GREEN}[x] $((i+1)). $name${NC}"
        else
            echo -e "[ ] $((i+1)). $name"
        fi
    done
    echo "------------------------------------------"
}

# --- 1. 交互选择逻辑 ---
while true; do
    show_menu
    read -p "请输入选项: " input
    if [ -z "$input" ]; then break; fi

    if [[ "$input" =~ ^[aA]$ ]]; then
        for ((i=0; i<${#APPS_DATA[@]}; i++)); do SELECTED_STATUS[$i]=1; done
        continue
    elif [[ "$input" =~ ^[nN]$ ]]; then
        for ((i=0; i<${#APPS_DATA[@]}; i++)); do SELECTED_STATUS[$i]=0; done
        continue
    fi

    for num in $input; do
        if [[ "$num" =~ ^[0-9]+$ ]]; then
            idx=$((num-1))
            if [ $idx -ge 0 ] && [ $idx -lt ${#APPS_DATA[@]} ]; then
                if [ "${SELECTED_STATUS[$idx]}" -eq 1 ]; then
                    SELECTED_STATUS[$idx]=0
                else
                    SELECTED_STATUS[$idx]=1
                fi
            fi
        fi
    done
done

# --- 2. 构建安装列表 ---
INSTALL_LIST=""
for ((i=0; i<${#APPS_DATA[@]}; i++)); do
    if [ "${SELECTED_STATUS[$i]}" -eq 1 ]; then
        IFS='|' read -r name pkg <<< "${APPS_DATA[$i]}"
        INSTALL_LIST="$INSTALL_LIST $pkg"
    fi
done

if [ -z "$INSTALL_LIST" ]; then
    echo "未选择任何软件，退出。"
    exit 0
fi

# --- 3. 执行安装 ---
echo -e "\n${YELLOW}即将安装:${NC} $INSTALL_LIST"
echo -e "${BLUE}开始调用 Paru 安装...${NC}"
paru -S --noconfirm $INSTALL_LIST

# --- 4. 配置 CLI 工具 (Fish) ---
echo -e "\n${BLUE}>>> 配置 CLI 工具环境 (config.fish)...${NC}"

mkdir -p "$(dirname "$FISH_CONFIG")"
touch "$FISH_CONFIG"

CONFIG_BLOCK=""

# A. 配置 Eza (ls 替代品)
if pacman -Qi eza &>/dev/null; then
    if ! grep -q "alias ls=\"eza" "$FISH_CONFIG"; then
        echo "添加 Eza 别名 (ls/ll)..."
        CONFIG_BLOCK="$CONFIG_BLOCK

# --- Eza Aliases ---
alias ls=\"eza --icons --color=always\"
alias ll=\"eza -l --color=always --icons --group-directories-first --time-style=relative --git-ignore --header --git\"
alias lt=\"eza --tree --level=2 --icons\""
# 顺便送你一个 lt 命令，直接用 eza 显示树状图
    fi
fi

# B. 配置 Zoxide (智能 cd)
if pacman -Qi zoxide &>/dev/null; then
    if ! grep -q "zoxide init fish" "$FISH_CONFIG"; then
        echo "添加 Zoxide 初始化..."
        CONFIG_BLOCK="$CONFIG_BLOCK

# --- Zoxide Init ---
zoxide init fish | source"
    fi
fi

# C. 配置 Fzf (模糊搜索)
if pacman -Qi fzf &>/dev/null; then
    if ! grep -q "fzf --fish" "$FISH_CONFIG"; then
        echo "添加 Fzf 初始化..."
        CONFIG_BLOCK="$CONFIG_BLOCK

# --- Fzf Init ---
fzf --fish | source"
    fi
fi

# D. 配置 Bat (高亮 cat & Manpage)
if pacman -Qi bat &>/dev/null; then
    if ! grep -q "alias cat=\"bat" "$FISH_CONFIG"; then
        echo "添加 Bat 别名及 Manpage 配置..."
        CONFIG_BLOCK="$CONFIG_BLOCK

# --- Bat Alias & Manpager ---
alias cat=\"bat\"
# 让 man 手册也拥有语法高亮
set -gx MANPAGER \"sh -c 'col -bx | bat -l man -p'\""
    fi
fi

# E. [新增] 配置 Tree (颜色支持)
if pacman -Qi tree &>/dev/null; then
    if ! grep -q "alias tree=" "$FISH_CONFIG"; then
        echo "添加 Tree 颜色配置..."
        CONFIG_BLOCK="$CONFIG_BLOCK

# --- Tree Alias ---
# 强制开启颜色显示
alias tree=\"tree -C\""
    fi
fi

# F. 写入配置
if [ -n "$CONFIG_BLOCK" ]; then
    echo "$CONFIG_BLOCK" >> "$FISH_CONFIG"
    echo -e "${GREEN}config.fish 已更新。${NC}"
else
    echo "config.fish 无需更新。"
fi

# G. 更新 Tldr 数据库
if pacman -Qi tealdeer &>/dev/null; then
    echo -e "${BLUE}更新 Tldr 数据库...${NC}"
    tldr --update || echo -e "${YELLOW}Tldr 更新失败，请稍后重试${NC}"
fi

echo -e "\n${GREEN}>>> 应用安装与配置全部完成！${NC}"
echo -e "提示: 请输入 ${YELLOW}source ~/.config/fish/config.fish${NC} 或重启终端以应用新配置。"
