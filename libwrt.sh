#!/bin/bash
# libwrt.sh - LiBwrt OpenWrt DIY脚本（安全版本）

# 定义工作目录
cd openwrt || exit 1

# 检测并移除 Athena LED 插件（feeds更新后可能在 package/feeds/ 目录）
find package -type d -name "luci-app-athena-led" -exec rm -rf {} + 2>/dev/null

# 克隆自定义版本
if [ ! -d "package/luci-app-athena-led" ]; then
    git clone --depth=1 https://github.com/NONGFAH/luci-app-athena-led package/luci-app-athena-led
fi

# 安全设置执行权限
chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led 2>/dev/null || true
chmod +x package/luci-app-athena-led/root/usr/sbin/athena-led 2>/dev/null || true

echo "DIY脚本执行完成"
