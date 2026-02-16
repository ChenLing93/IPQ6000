#!/bin/bash 
echo "=== LiBwrt DIY 脚本开始执行 ==="
echo "步骤 1: 复制增强 feeds 配置..."
if [ -f "feeds_theme_enhanced.conf.default" ]; then
    cp feeds_theme_enhanced.conf.default feeds.conf.default
    echo "✓ 已应用增强 feeds 配置"
else
    echo "⚠ feeds_theme_enhanced.conf.default 不存在，使用默认配置"
fi

echo "步骤 2: 更新 feeds（重要！）"
./scripts/feeds clean
./scripts/feeds update -a
./scripts/feeds install -a

echo "步骤 3: 验证关键包..."
# 检查 Proton2025
if [ -d "feeds/luci/luci-theme-proton2025" ] || [ -d "package/luci-theme-proton2025" ]; then
    echo "✓ Proton2025 主题已安装"
else
    echo "✗ Proton2025 主题未找到"
fi
# 检查 GecoOS AC
if [ -d "feeds/packages/gecoosac" ] || [ -d "feeds/luci/applications/luci-app-gecoos-ac" ] || [ -d "package/luci-app-gecoosac" ]; then
    echo "✓ GecoOS AC 已安装"
else
    echo "✗ GecoOS AC 未找到"
fi
# 检查 iStore
if [ -d "feeds/packages/istore" ] || [ -d "feeds/luci/istore" ] || [ -d "package/app-store-ui" ]; then
    echo "✓ iStore 已安装"
else
    echo "✗ iStore 未找到"
fi

# 修改默认IP
sed -i 's/192.168.5.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录
if [ -f "feeds/packages/utils/ttyd/files/ttyd.config" ]; then
    sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config
fi

# 移除要替换的包（只在 feeds 中存在时删除）
rm -rf feeds/packages/net/mosdns 2>/dev/null
rm -rf feeds/packages/net/msd_lite 2>/dev/null
rm -rf feeds/packages/net/smartdns 2>/dev/null
rm -rf feeds/luci/applications/luci-app-mosdns 2>/dev/null
rm -rf feeds/luci/applications/luci-app-netdata 2>/dev/null
rm -rf feeds/luci/applications/luci-app-serverchan 2>/dev/null

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
    branch="$1"
    repourl="$2" && shift 2
    git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
    repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
    cd $repodir && git sparse-checkout set $@
    mv -f $@ ../package
    cd .. && rm -rf $repodir
}

# 添加额外插件
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
git clone --depth=1 -b openwrt-18.06 https://github.com/tty228/luci-app-wechatpush package/luci-app-serverchan
git clone --depth=1 https://github.com/ilxp/luci-app-ikoolproxy package/luci-app-ikoolproxy
git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff
git clone --depth=1 https://github.com/destan19/OpenAppFilter package/OpenAppFilter
git clone --depth=1 https://github.com/Jason6111/luci-app-netdata package/luci-app-netdata

git_sparse_clone main https://github.com/Lienol/openwrt-package luci-app-file浏览器 luci-app-ssr-mudb-server
git_sparse_clone openwrt-18.06 https://github.com/immortalwrt/luci applications/luci-app-eqos

# 主题（通过 feeds 管理的跳过，手动添加缺失的主题）
git clone --depth=1 -b 18.06 https://github.com/kiddin9/luci-theme-edge package/luci-theme-edge
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom package/luci-theme-infinityfreedom
git_sparse_clone main https://github.com/haiibo/packages luci-theme-atmaterial luci-theme-opentomcat luci-theme-netgear

# 晶晨宝盒
git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic
sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/haiibo/OpenWrt'|g" package/luci-app-amlogic/root/etc/config/amlogic
# sed -i "s|kernel_path.*|kernel_path 'https://github.com/ophub/kernel'|g" package/luci-app-amlogic/root/etc/config/amlogic
sed -i "s|ARMv8|ARMv8_PLUS|g" package/luci-app-amlogic/root/etc/config/amlogic

# SmartDNS
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# msd_lite
git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite package/luci-app-msd_lite
git clone --depth=1 https://github.com/ximiTech/msd_lite package/msd_lite

# MosDNS
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

# Alist
git clone --depth=1 https://github.com/sbwml/luci-app-alist package/luci-app-alist

# DDNS.to
git_sparse_clone main https://github.com/linkease/nas-packages-luci luci/luci-app-ddnsto
git_sparse_clone master https://github.com/linkease/nas-packages network/services/ddnsto

# iStore（修复路径问题）
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci

# GecoOS AC（手动添加）
git clone --depth=1 https://github.com/geco-os/openwrt-packages.git package/gecoos-packages
cd package/gecoos-packages
# 只保留 luci-app-gecoosac 相关文件
find . -maxdepth 1 ! -name 'luci-app-gecoosac' ! -name '.' ! -name '..' -exec rm -rf {} \;
mv luci-app-gecoosac* ../
cd ../..
rm -rf package/gecoos-packages

# 在线用户
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
    sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
fi
if [ -f "package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh" ]; then
    chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh
fi

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
fi

# 修复 hostapd 报错
if [ -n "$GITHUB_WORKSPACE" ] && [ -f "$GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch" ]; then
    cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch
fi

# 修复 armv8 设备 xfsprogs 报错
if [ -f "feeds/packages/utils/xfsprogs/Makefile" ]; then
    sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile
fi

# 修改 Makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {} 2>/dev/null
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {} 2>/dev/null
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {} 2>/dev/null
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {} 2>/dev/null

# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

# 调整 V2ray服务器 到 VPN 菜单
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/controller/*.lua
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/model/cbi/v2ray_server/*.lua
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/view/v2ray_server/*.htm

# 重新更新和安装 feeds
echo "=== 重新更新和安装 Feeds ==="
./scripts/feeds update -a
./scripts/feeds install -a

echo "=== 最终验证关键包 ==="
# 检查 Proton2025
if [ -d "feeds/luci/luci-theme-proton2025" ] || [ -d "package/luci-theme-proton2025" ]; then
    echo "✓ Proton2025 主题已就绪"
else
    echo "✗ Proton2025 主题未找到"
fi
# 检查 Argon
if [ -d "feeds/luci/luci-theme-argon" ] || [ -d "package/luci-theme-argon" ]; then
    echo "✓ Argon 主题已就绪"
else
    echo "✗ Argon 主题未找到"
fi
# 检查 Aurora
if [ -d "feeds/luci/luci-theme-aurora" ] || [ -d "package/luci-theme-aurora" ]; then
    echo "✓ Aurora 主题已就绪"
else
    echo "✗ Aurora 主题未找到"
fi
# 检查 GecoOS AC
if [ -d "feeds/packages/gecoosac" ] || [ -d "feeds/luci/applications/luci-app-gecoos-ac" ] || [ -d "package/luci-app-gecoosac" ]; then
    echo "✓ GecoOS AC 已就绪"
else
    echo "✗ GecoOS AC 未找到"
fi
# 检查 iStore
if [ -d "feeds/packages/istore" ] || [ -d "feeds/luci/istore" ] || [ -d "package/app-store-ui" ]; then
    echo "✓ iStore 已就绪"
else
    echo "✗ iStore 未找到"
fi
echo "=== DIY 脚本执行完成 ==="
