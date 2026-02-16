rm -rf package/emortal/luci-app-athena-led
git clone --depth=1 https://github.com/NONGFAH/luci-app-athena-led package/luci-app-athena-led
chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led package/luci-app-athena-led/root/usr/sbin/athena-led

src-git packages https://github.com/LiBwrt/openwrt-packages.git;main-nss
src-git luci https://github.com/LiBwrt/openwrt-luci.git;main-nss
src-git routing https://github.com/LiBwrt/openwrt-routing.git;main-nss
src-git telephony https://github.com/openwrt/telephony.git;openwrt-24.10

# iStore 源
src-git istore https://github.com/linkease/istore.git;main
src-git istore-ui https://github.com/linkease/istore-ui.git;main

# GecoOS AC 源
src-git gecoos https://github.com/geco-os/openwrt-packages.git;main

# 主题相关源
src-git luci-theme-proton2025 https://github.com/kiddin9/luci-theme-proton2025.git;master
src-git luci-theme-argon https://github.com/jerrykuku/luci-theme-argon.git;master
src-git luci-theme-aurora https://github.com/xiaoqingfengATGH/luci-theme-aurora.git;master
src-git luci-theme-kucat https://github.com/linkease/nas-packages-luci.git;main
src-git luci-theme-neobird https://github.com/thinktip/luci-theme-neobird.git;master
