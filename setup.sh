#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# 获取脚本当前绝对路径
export BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
export MODULES_DIR="$BASE_DIR/modules"
export ASSETS_DIR="$BASE_DIR/assets"

clear
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}   Garuda Linux 自动化配置脚本 (Fish版)   ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# --- 交互部分：确认执行 ---
read -p "是否开始执行安装脚本？(y/n): " choice
case "$choice" in
  y|Y )
    echo -e "${GREEN}>>> 确认执行，脚本启动...${NC}"
    ;;
  n|N )
    echo -e "${RED}>>> 用户取消，退出脚本。${NC}"
    exit 0
    ;;
  * )
    echo -e "${RED}>>> 输入无效，退出脚本。${NC}"
    exit 1
    ;;
esac

# 赋予所有子脚本执行权限
chmod +x "$MODULES_DIR"/*.sh 2>/dev/null || true

# --- 按顺序调用模块 ---

# 模块 1: ArchLinuxCN
echo -e "\n${GREEN}>>> [1/3] 正在执行 ArchLinuxCN 配置模块...${NC}"
"$MODULES_DIR/01_archlinuxcn.sh"

# 模块 2: V2Ray & Network
echo -e "\n${GREEN}>>> [2/3] 正在执行 V2Ray 网络代理模块...${NC}"
"$MODULES_DIR/02_v2ray.sh"

# 模块 3: Fcitx5 输入法
echo -e "\n${GREEN}>>> [3/3] 正在执行输入法模块...${NC}"
"$MODULES_DIR/03_fcitx5.sh"

echo -e "\n${BLUE}=========================================${NC}"
echo -e "${BLUE}   所有任务执行完毕！请重启系统。        ${NC}"
echo -e "${BLUE}=========================================${NC}"
