#!/bin/bash

# 颜色定义
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export RED='\033[0;31m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

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

# --- 动态调用模块 ---

# 赋予所有子脚本执行权限
chmod +x "$MODULES_DIR"/*.sh 2>/dev/null || true

# 获取所有模块脚本
modules=($(ls "$MODULES_DIR"/*.sh | sort))
module_count=${#modules[@]}
current_module=1

# 循环执行所有模块
for module_path in "${modules[@]}"; do
    module_name=$(basename "$module_path")
    echo -e "\n${BLUE}>>> [${current_module}/${module_count}] 正在执行模块: ${module_name}${NC}"

    # 执行模块脚本
    if ! "$module_path"; then
        echo -e "\n${RED}✗ 模块 ${module_name} 执行失败，已中断脚本。${NC}"
        echo -e "${YELLOW}请检查以上错误信息。${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ 模块 ${module_name} 执行完成。${NC}"
    ((current_module++))
done

echo -e "\n${BLUE}=========================================${NC}"
echo -e "${GREEN}   所有任务执行完毕！请重启系统。        ${NC}"
echo -e "${BLUE}=========================================${NC}"
