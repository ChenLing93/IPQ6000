#!/bin/bash

if [ ! -f "scripts/feeds" ]; then
    echo "错误：未找到OpenWrt源码目录"
    exit 1
fi

echo "开始执行DIY脚本..."

if [ -d "package/emortal/luci-app-athena-led" ]; then
    echo "移除旧的Athena LED插件..."
    rm -rf package/emortal/luci-app-athena-led
fi

echo "克隆Athena LED插件..."
git clone --depth=1 https://github.com/NONGFAH/luci-app-athena-led package/luci-app-athena-led

if [ -f "package/luci-app-athena-led/root/etc/init.d/athena_led" ]; then
    chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led
fi

if [ -f "package/luci-app-athena-led/root/usr/sbin/athena-led" ]; then
    chmod +x package/luci-app-athena-led/root/usr/sbin/athena-led
fi

echo "DIY脚本执行完成"
EOF
