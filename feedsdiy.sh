#!/bin/sh
# shellcheck disable=SC2086,SC3043,SC2164,SC2103,SC2046,SC2155
source /etc/profile
BASE_PATH=$(cd $(dirname $0) && pwd)

# ================= [新增] 添加 IStore 官方源 =================
echo "=== 正在添加 IStore 官方源 ==="

# 1. 清理可能存在的旧目录，防止冲突
rm -rf feeds/istore
rm -rf package/istore

# 2. 克隆 IStore 官方仓库 (使用 --depth=1 加速)
if git clone https://github.com/linkease/istore.git feeds/istore --depth=1; then
    echo "IStore 源码克隆成功"
    
    # 3. 更新 IStore 索引
    ./scripts/feeds update istore
    
    # 4. 安装 IStore 核心组件 (store, taskd, xterm)
    ./scripts/feeds install -p istore luci-app-store luci-lib-taskd luci-lib-xterm
    echo "IStore 核心组件安装完成"
else
    echo "⚠️ 警告: IStore 源码克隆失败，请检查网络连接或 GitHub 状态"
fi
# ================= IStore 添加结束 =================

# --- 原有清理操作 ---
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/packages/net/open-app-filter
# rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
# rm -rf feeds/luci/themes/luci-theme-netgear
rm -rf feeds/luci/applications/luci-app-adguardhome
rm -rf feeds/luci/applications/luci-app-mosdns
# rm -rf feeds/luci/applications/luci-app-netdata
# rm -rf feeds/luci/applications/luci-app-serverchan
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/applications/luci-app-homeproxy
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-ssr-plus
rm -rf feeds/packages/net/trojan-plus
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/v2ray-plugin
rm -rf feeds/packages/net/v2ray-core
rm -rf feeds/packages/net/shadowsocks-rust
rm -rf feeds/packages/net/xray-core
rm -rf feeds/packages/utils/v2dat

# --- 原有函数定义 ---
install_small8() {
    # 注意：已从列表中移除 luci-app-store, luci-lib-taskd, luci-lib-xterm
    # 因为上面已经通过官方源安装了最新版，避免被 small8 的旧版本覆盖
    ./scripts/feeds install -p small8 -f xray-core xray-plugin dns2tcp dns2socks haproxy hysteria \
        naiveproxy shadowsocks-rust sing-box v2ray-core v2ray-geodata v2ray-geoview v2ray-plugin \
        tuic-client chinadns-ng ipt2socks tcping trojan-plus simple-obfs shadowsocksr-libev \
        luci-app-passwall alist luci-app-alist smartdns luci-app-smartdns v2dat mosdns luci-app-mosdns \
        adguardhome luci-app-adguardhome ddns-go luci-app-ddns-go taskd luci-lib-xterm luci-lib-taskd \
        luci-app-quickstart luci-app-istorex luci-app-cloudflarespeedtest \
        luci-theme-argon netdata luci-app-netdata lucky luci-app-lucky luci-app-openclash luci-app-homeproxy \
        luci-app-amlogic nikki luci-app-nikki tailscale luci-app-tailscale oaf open-app-filter luci-app-oaf \
        easytier luci-app-easytier msd_lite luci-app-msd_lite luci-app-argon-config cups luci-app-cupsd
}

# fix_miniupmpd() {
#     local PKG_HASH=$(awk -F"=" '/^PKG_HASH:/ {print $2}' ./feeds/packages/net/miniupnpd/Makefile)
#     if [[ $PKG_HASH == "fbdd5501039730f04a8420ea2f8f54b7df63f9f04cde2dc67fa7371e80477bbe" ]]; then
#         if [[ -f $BASE_PATH/patches/400-fix_nft_miniupnp.patch ]]; then
#             if [[ ! -d ./feeds/packages/net/miniupnpd/patches ]]; then
#                 mkdir -p ./feeds/packages/net/miniupnpd/patches
#             fi
#             \cp -f $BASE_PATH/patches/400-fix_nft_miniupnp.patch ./feeds/packages/net/miniupnpd/patches/
#         fi
#     fi
# }

# remove_unwanted_packages
install_small8
# fix_miniupmpd
