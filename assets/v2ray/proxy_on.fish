#!/usr/bin/env fish

# V2Ray 代理开启脚本 (适配 Garuda Linux)

set PROXY_SERVER "127.0.0.1"
set PROXY_PORT "10808"
set PROXY_PORT_HTTP "10809"

# 检查 V2Ray 服务状态
if not systemctl is-active --quiet v2ray.service
    echo "V2Ray 服务未运行，正在启动..."
    sudo systemctl start v2ray.service
    sleep 1
end

# 再次检查服务是否成功启动
if not systemctl is-active --quiet v2ray.service
    echo "❌ 错误：V2Ray 服务启动失败。"
    echo "   请检查配置文件：/etc/v2ray/config.json"
    echo "   查看日志：sudo journalctl -u v2ray -n 50"
    return 1
end

echo "✓ V2Ray 服务运行中"

# 设置 Fish 终端代理环境变量
set -gx http_proxy "http://$PROXY_SERVER:$PROXY_PORT_HTTP"
set -gx https_proxy "http://$PROXY_SERVER:$PROXY_PORT_HTTP"
set -gx ftp_proxy "http://$PROXY_SERVER:$PROXY_PORT_HTTP"
set -gx all_proxy "socks5://$PROXY_SERVER:$PROXY_PORT"
set -gx HTTP_PROXY "http://$PROXY_SERVER:$PROXY_PORT_HTTP"
set -gx HTTPS_PROXY "http://$PROXY_SERVER:$PROXY_PORT_HTTP"
set -gx ALL_PROXY "socks5://$PROXY_SERVER:$PROXY_PORT"

echo "✓ Fish 终端代理已开启"

# 3. [新增] 设置 Git 全局代理
if command -v git >/dev/null 2>&1
    git config --global http.proxy "http://$PROXY_SERVER:$PROXY_PORT_HTTP"
    git config --global https.proxy "http://$PROXY_SERVER:$PROXY_PORT_HTTP"
    echo "✓ Git 全局代理已设置"
end

# 4. [新增] 设置 Root/Sudo 代理能力
# 通过创建临时 sudoers 配置，允许 sudo 命令继承代理相关的环境变量
# 这能确保 sudo pacman, sudo flatpak 等命令也能走代理
echo "Defaults env_keep += \"http_proxy https_proxy ftp_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY\"" | sudo tee /etc/sudoers.d/temp_proxy_keep >/dev/null
# 赋予正确的权限 (0440)
sudo chmod 0440 /etc/sudoers.d/temp_proxy_keep
echo "✓ Sudo/Root 代理权限已配置"

# 检测桌面环境并设置系统代理
if set -q XDG_CURRENT_DESKTOP
    switch $XDG_CURRENT_DESKTOP
        case '*KDE*' '*Plasma*'
            # 检测 KDE Plasma 版本
            if command -v kwriteconfig6 >/dev/null 2>&1
                # Plasma 6
                kwriteconfig6 --file kioslaverc --group "Proxy Settings" --key "ProxyType" "1"
                kwriteconfig6 --file kioslaverc --group "Proxy Settings" --key "socksProxy" "$PROXY_SERVER $PROXY_PORT"
                kwriteconfig6 --file kioslaverc --group "Proxy Settings" --key "httpProxy" "$PROXY_SERVER $PROXY_PORT_HTTP"
                kwriteconfig6 --file kioslaverc --group "Proxy Settings" --key "httpsProxy" "$PROXY_SERVER $PROXY_PORT_HTTP"

                # 刷新 KDE 配置
                dbus-send --type=signal /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration string:"" 2>/dev/null
                echo "✓ KDE Plasma 6 系统代理已开启"

            else if command -v kwriteconfig5 >/dev/null 2>&1
                # Plasma 5
                kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key "ProxyType" "1"
                kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key "socksProxy" "$PROXY_SERVER $PROXY_PORT"
                kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key "httpProxy" "$PROXY_SERVER $PROXY_PORT_HTTP"
                kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key "httpsProxy" "$PROXY_SERVER $PROXY_PORT_HTTP"

                # 刷新 KDE 配置
                dbus-send --type=signal /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration string:"" 2>/dev/null
                echo "✓ KDE Plasma 5 系统代理已开启"
            else
                echo "⚠ 警告：未找到 kwriteconfig 工具，KDE 系统代理未设置"
            end

        case '*GNOME*'
            # GNOME 桌面
            if command -v gsettings >/dev/null 2>&1
                gsettings set org.gnome.system.proxy mode 'manual'
                gsettings set org.gnome.system.proxy.http host "$PROXY_SERVER"
                gsettings set org.gnome.system.proxy.http port $PROXY_PORT_HTTP
                gsettings set org.gnome.system.proxy.https host "$PROXY_SERVER"
                gsettings set org.gnome.system.proxy.https port $PROXY_PORT_HTTP
                gsettings set org.gnome.system.proxy.socks host "$PROXY_SERVER"
                gsettings set org.gnome.system.proxy.socks port $PROXY_PORT
                echo "✓ GNOME 系统代理已开启"
            else
                echo "⚠ 警告：未找到 gsettings 工具，GNOME 系统代理未设置"
            end

        case '*'
            echo "⚠ 检测到非 KDE/GNOME 桌面环境：$XDG_CURRENT_DESKTOP"
            echo "  系统级代理未设置，但终端代理已生效"
    end
else
    echo "⚠ 无法检测桌面环境，仅设置终端代理"
end

echo ""
echo "🚀 全局代理已开启 (包含 Shell, Git, Sudo, GUI)"
echo "   SOCKS5: socks5://$PROXY_SERVER:$PROXY_PORT"
echo "   HTTP/HTTPS: http://$PROXY_SERVER:$PROXY_PORT_HTTP"
echo ""
echo "测试代理："
echo "  curl -I https://www.google.com"
