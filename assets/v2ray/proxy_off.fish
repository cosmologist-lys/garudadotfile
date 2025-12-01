#!/usr/bin/env fish

# V2Ray 代理关闭脚本 (适配 Garuda Linux)

echo "正在关闭代理..."

# 清除 Fish 终端代理环境变量
set -e http_proxy
set -e https_proxy
set -e ftp_proxy
set -e all_proxy
set -e HTTP_PROXY
set -e HTTPS_PROXY
set -e ALL_PROXY

echo "✓ 终端代理已关闭"

# 检测桌面环境并关闭系统代理
if set -q XDG_CURRENT_DESKTOP
    switch $XDG_CURRENT_DESKTOP
        case '*KDE*' '*Plasma*'
            # 检测 KDE Plasma 版本
            if command -v kwriteconfig6 >/dev/null 2>&1
                # Plasma 6 - 设置为无代理
                kwriteconfig6 --file kioslaverc --group "Proxy Settings" --key "ProxyType" "0"
                dbus-send --type=signal /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration string:"" 2>/dev/null
                echo "✓ KDE Plasma 6 系统代理已关闭"

            else if command -v kwriteconfig5 >/dev/null 2>&1
                # Plasma 5 - 设置为无代理
                kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key "ProxyType" "0"
                dbus-send --type=signal /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration string:"" 2>/dev/null
                echo "✓ KDE Plasma 5 系统代理已关闭"
            else
                echo "⚠ 警告：未找到 kwriteconfig 工具"
            end

        case '*GNOME*'
            # GNOME 桌面 - 设置为无代理
            if command -v gsettings >/dev/null 2>&1
                gsettings set org.gnome.system.proxy mode 'none'
                echo "✓ GNOME 系统代理已关闭"
            else
                echo "⚠ 警告：未找到 gsettings 工具"
            end

        case '*'
            echo "⚠ 检测到非 KDE/GNOME 桌面环境：$XDG_CURRENT_DESKTOP"
    end
else
    echo "⚠ 无法检测桌面环境"
end

# 询问是否停止 V2Ray 服务
echo ""
read -P "是否停止 V2Ray 服务？(y/N): " -n 1 stop_service

if test "$stop_service" = "y" -o "$stop_service" = "Y"
    if systemctl is-active --quiet v2ray.service
        sudo systemctl stop v2ray.service
        echo "✓ V2Ray 服务已停止"
    else
        echo "V2Ray 服务未运行"
    end
else
    echo "V2Ray 服务保持运行"
end

echo ""
echo "🔒 代理已关闭"
