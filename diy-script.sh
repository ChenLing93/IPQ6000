#!/bin/bash 
# ============================================
# LiBwrt DIY 脚本（IPQ60XX 6.12 无WIFI版本）
# ============================================

#echo "=== LiBwrt DIY 脚本开始执行 ==="

# ============================================
# 步骤 1: 系统基础配置
# ============================================
#echo "步骤 1: 系统基础配置..."

# 修改默认IP
sed -i 's/192.168.5.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录
if [ -f "feeds/packages/utils/ttyd/files/ttyd.config" ]; then
    sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config
    echo "✓ TTYD 免登录已配置"
fi

# ============================================
# 步骤 2: 移除要替换的包
# ============================================
echo "步骤 2: 移除要替换的包..."

rm -rf feeds/packages/net/mosdns 2>/dev/null
rm -rf feeds/packages/net/msd_lite 2>/dev/null
rm -rf feeds/packages/net/smartdns 2>/dev/null

# 移除 feeds 中的主题（使用手动克隆的版本）
rm -rf feeds/luci/themes/luci-theme-argon 2>/dev/null
rm -rf feeds/luci/themes/luci-theme-netgear 2>/dev/null

rm -rf feeds/luci/applications/luci-app-mosdns 2>/dev/null
rm -rf feeds/luci/applications/luci-app-netdata 2>/dev/null
rm -rf feeds/luci/applications/luci-app-serverchan 2>/dev/null

echo "✓ 已移除需要替换的包"

# ============================================
# 步骤 3: Git稀疏克隆函数
# ============================================
function git_sparse_clone() {
    branch="$1"
    repourl="$2" && shift 2
    
    echo "  正在克隆: $repourl (分支: $branch)"
    git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
    
    repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
    cd $repodir
    git sparse-checkout set $@
    mv -f $@ ../package
    cd ..
    rm -rf $repodir
    echo "  ✓ 完成克隆: $@"
}

# ============================================
# 步骤 4: 添加额外插件
# ============================================
echo "步骤 4: 添加额外插件..."

echo "  添加 AdGuardHome..."
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome

echo "  添加 ServerChan..."
git clone --depth=1 -b openwrt-18.06 https://github.com/tty228/luci-app-wechatpush package/luci-app-serverchan

echo "  添加 KoolProxy..."
git clone --depth=1 https://github.com/ilxp/luci-app-ikoolproxy package/luci-app-ikoolproxy

echo "  添加 PowerOff..."
git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff

echo "  添加 OpenAppFilter..."
git clone --depth=1 https://github.com/destan19/OpenAppFilter package/OpenAppFilter

echo "  添加 Netdata..."
git clone --depth=1 https://github.com/Jason6111/luci-app-netdata package/luci-app-netdata

echo "  添加 FileBrowser 和 SSR Mudb Server..."
git_sparse_clone main https://github.com/Lienol/openwrt-package luci-app-filebrowser luci-app-ssr-mudb-server

echo "  添加 Eqos..."
git_sparse_clone openwrt-18.06 https://github.com/immortalwrt/luci applications/luci-app-eqos

# ============================================
# 步骤 5: 添加主题
# ============================================
echo "步骤 5: 添加主题..."

echo "  添加 Edge 主题..."
git clone --depth=1 -b 18.06 https://github.com/kiddin9/luci-theme-edge package/luci-theme-edge

echo "  添加 Argon 主题..."
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon

echo "  添加 Argon 配置工具..."
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

echo "  添加 Infinity Freedom 主题..."
git clone --depth=1 https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom package/luci-theme-infinityfreedom

echo "  添加 ATMaterial、OpenTomcat、Netgear 主题..."
git_sparse_clone main https://github.com/haiibo/packages luci-theme-atmaterial luci-theme-opentomcat luci-theme-netgear

# 更改 Argon 主题背景
if [ -n "$GITHUB_WORKSPACE" ] && [ -f "$GITHUB_WORKSPACE/images/bg1.jpg" ]; then
    cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
    echo "  ✓ 已替换 Argon 主题背景"
fi

# ============================================
# 步骤 6: 添加晶晨宝盒
# ============================================
echo "步骤 6: 添加晶晨宝盒..."
git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic
sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/haiibo/OpenWrt'|g" package/luci-app-amlogic/root/etc/config/amlogic
# sed -i "s|kernel_path.*|kernel_path 'https://github.com/ophub/kernel'|g" package/luci-app-amlogic/root/etc/config/amlogic
sed -i "s|ARMv8|ARMv8_PLUS|g" package/luci-app-amlogic/root/etc/config/amlogic

# ============================================
# 步骤 7: 添加 DNS 工具
# ============================================
echo "步骤 7: 添加 DNS 工具..."

echo "  添加 SmartDNS..."
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

echo "  添加 msd_lite..."
git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite package/luci-app-msd_lite
git clone --depth=1 https://github.com/ximiTech/msd_lite package/msd_lite

git clone --depth=1 https://github.com/lwb1978/openwrt-gecoosac package/openwrt-gecoosac
echo "  添加 MosDNS..."
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

echo "  添加 Alist..."
git clone --depth=1 https://github.com/sbwml/luci-app-alist package/luci-app-alist

git clone --depth=1  https://github.com/kiddin9/luci-theme-proton2025  package/luci-theme-proton2025
# 步骤 8: 添加 DDNS.to
# ============================================
echo "步骤 8: 添加 DDNS.to..."
git_sparse_clone main https://github.com/linkease/nas-packages-luci luci/luci-app-ddnsto
git_sparse_clone master https://github.com/linkease/nas-packages network/services/ddnsto

# ============================================
# 步骤 9: 添加 iStore
# ============================================
echo "步骤 9: 添加 iStore..."
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci



# ============================================
# 步骤 10: 添加在线用户


# ============================================
echo "步骤 10: 添加在线用户..."
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner

if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
    sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
fi

if [ -f "package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh" ]; then
    chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh
fi

# ============================================
# 步骤 11: 系统优化
# ============================================
echo "步骤 11: 系统优化..."

# x86 型号只显示 CPU 型号
if [ -f "package/lean/autocore/files/x86/autocore" ]; then
    sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore
fi

# 修改本地时间格式
find package/lean/autocore/files/*/index.htm -type f -exec sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' {} \;

# 修改版本为编译日期
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    date_version=$(date +"%y.%m.%d")
    orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
    sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings
    echo "✓ 版本号已更新为: R${date_version} by Haiibo"
fi

# ============================================
# 步骤 12: 修复编译问题
# ============================================
echo "步骤 12: 修复编译问题..."

# 修复 hostapd 报错
if [ -n "$GITHUB_WORKSPACE" ] && [ -f "$GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch" ]; then
    cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch
    echo "✓ 已应用 hostapd 补丁"
fi

# 修复 armv8 设备 xfsprogs 报错
if [ -f "feeds/packages/utils/xfsprogs/Makefile" ]; then
    sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile
    echo "✓ 已修复 xfsprogs 编译问题"
fi

# ============================================
# 步骤 13: 修改 Makefile
# ============================================
echo "步骤 13: 修改 Makefile..."

find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {} 2>/dev/null
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {} 2>/dev/null
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {} 2>/dev/null
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {} 2>/dev/null

# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

# 调整 V2ray服务器 到 VPN 菜单（已禁用）
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/controller/*.lua
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/model/cbi/v2ray_server/*.lua
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/view/v2ray_server/*.htm

# ============================================
# 步骤 14: 重新更新和安装 Feeds
# ============================================
echo "步骤 14: 重新更新和安装 Feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# ============================================
# 步骤 15: 最终验证
# ============================================
echo ""
echo "=== 最终验证关键插件和主题 ==="

echo "✓ AdGuardHome: $([ -d "package/luci-app-adguardhome" ] && echo '已安装' || echo '未找到')"
echo "✓ ServerChan: $([ -d "package/luci-app-serverchan" ] && echo '已安装' || echo '未找到')"
echo "✓ KoolProxy: $([ -d "package/luci-app-ikoolproxy" ] && echo '已安装' || echo '未找到')"
echo "✓ SmartDNS: $([ -d "package/luci-app-smartdns" ] && echo '已安装' || echo '未找到')"
echo "✓ MosDNS: $([ -d "package/luci-app-mosdns" ] && echo '已安装' || echo '未找到')"
echo "✓ Alist: $([ -d "package/luci-app-alist" ] && echo '已安装' || echo '未找到')"
echo "✓ DDNSTO: $([ -d "package/luci-app-ddnsto" ] && echo '已安装' || echo '未找到')"
echo "✓ iStore: $([ -d "package/app-store-ui" ] && echo '已安装' || echo '未找到')"
echo "✓ 晶晨宝盒: $([ -d "package/luci-app-amlogic" ] && echo '已安装' || echo '未找到')"
echo "✓ 在线用户: $([ -d "package/luci-app-onliner" ] && echo '已安装' || echo '未找到')"
echo "✓ Edge 主题: $([ -d "package/luci-theme-edge" ] && echo '已安装' || echo '未找到')"
echo "✓ Argon 主题: $([ -d "package/luci-theme-argon" ] && echo '已安装' || echo '未找到')"
echo "✓ InfinityFreedom 主题: $([ -d "package/luci-theme-infinityfreedom" ] && echo '已安装' || echo '未找到')"
echo "✓ ATMaterial 主题: $([ -d "package/luci-theme-atmaterial" ] && echo '已安装' || echo '未找到')"
echo "✓ OpenTomcat 主题: $([ -d "package/luci-theme-opentomcat" ] && echo '已安装' || echo '未找到')"
echo "✓ Netgear 主题: $([ -d "package/luci-theme-netgear" ] && echo '已安装' || echo '未找到')"

echo ""
echo "=== LiBwrt DIY 脚本执行完成 ==="
