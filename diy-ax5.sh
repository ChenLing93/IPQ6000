#!/bin/bash
# ============================================
# OpenWrt Redmi AX5 NOWIFI 精简版 DIY 脚本
# 平台: Qualcomm IPQ6018 (Redmi AX5 NOWIFI)
# 内核: 6.12
# 特性: NSS 加速 + 精简优化
# 默认 IP: 192.168.5.1
# ============================================

# 1. 修改默认 IP 地址为 192.168.5.1
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/etc/config/network 2>/dev/null

# 2. 软件包更新函数定义
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4

	# 清理旧的包
	read -ra PKG_NAMES <<< "$PKG_NAME"
	for NAME in "${PKG_NAMES[@]}"; do
		rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" -prune) 2>/dev/null
	done

	# 克隆仓库
	if [[ $PKG_REPO == http* ]]; then
		local REPO_NAME=$(echo $PKG_REPO | awk -F '/' '{gsub(/\.git$/, "", $NF); print $NF}')
		git clone --depth=1 --single-branch --branch $PKG_BRANCH "$PKG_REPO" package/$REPO_NAME 2>/dev/null
	else
		local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)
		git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" package/$REPO_NAME 2>/dev/null
	fi

	# 处理包
	case "$PKG_SPECIAL" in
		"pkg")
			for NAME in "${PKG_NAMES[@]}"; do
				echo "moving $NAME from $REPO_NAME"
				cp -rf $(find ./package/$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$NAME*" -prune) ./package/ 2>/dev/null
			done
			rm -rf ./package/$REPO_NAME/
			;;
		"name")
			mv -f ./package/$REPO_NAME ./package/$PKG_NAME 2>/dev/null
			;;
	esac
}

# ============================================
# 3. 基础工具安装
# ============================================
UPDATE_PACKAGE "luci-app-poweroff" "esirplayground/luci-app-poweroff" "master"
UPDATE_PACKAGE "openwrt-gecoosac" "lwb1978/openwrt-gecoosac" "main"
UPDATE_PACKAGE "luci-app-openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"

# ============================================
# 4. 科学上网工具集 (已移除 OpenClash)
# ============================================
UPDATE_PACKAGE "xray-core xray-plugin dns2tcp dns2socks haproxy hysteria \
naiveproxy shadowsocks-rust v2ray-core v2ray-geodata v2ray-geoview v2ray-plugin \
tuic-client chinadns-ng ipt2socks tcping trojan-plus simple-obfs shadowsocksr-libev \
luci-app-passwall smartdns luci-app-smartdns v2dat mosdns luci-app-mosbnb \
taskd luci-lib-xterm luci-lib-taskd luci-app-ssr-plus luci-app-passwall2 \
luci-app-store quickstart luci-app-quickstart luci-app-istorex luci-app-cloudflarespeedtest \
luci-theme-argon netdata luci-app-netdata lucky luci-app-lucky \
luci-app-nikki luci-app-vlmcsd vlmcsd" "kenzok8/small-package" "main" "pkg"

# ============================================
# 5. 网络测速工具
# ============================================
UPDATE_PACKAGE "luci-app-netspeedtest" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"
UPDATE_PACKAGE "speedtest-cli" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"

# ============================================
# 6. 容器与文件工具
# ============================================
UPDATE_PACKAGE "openwrt-podman" "https://github.com/breeze303/openwrt-podman" "main"
UPDATE_PACKAGE "luci-app-quickfile" "https://github.com/sbwml/luci-app-quickfile" "main"
if [ -f "package/luci-app-quickfile/quickfile/Makefile" ]; then
    sed -i 's|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-$(ARCH_PACKAGES) $(1)/usr/bin/quickfile|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-aarch64_generic $(1)/usr/bin/quickfile|' package/luci-app-quickfile/quickfile/Makefile
fi

# ============================================
# 7. 磁盘管理工具
# ============================================
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname luci-app-diskman -prune) 2>/dev/null
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname parted -prune) 2>/dev/null
mkdir -p package/luci-app-diskman && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -O package/luci-app-diskman/Makefile 2>/dev/null
sed -i 's/fs-ntfs /fs-ntfs3 /g' package/luci-app-diskman/Makefile
sed -i '/ntfs-3g-utils /d' package/luci-app-diskman/Makefile
mkdir -p package/parted && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O package/parted/Makefile 2>/dev/null

# ============================================
# 8. 服务工具 (已移除 CUPS)
# ============================================
UPDATE_PACKAGE "frp" "https://github.com/ysuolmai/openwrt-frp.git" "master"
UPDATE_PACKAGE "ddnsto" "kenzok8/openwrt-packages" "master" "pkg"
# UPDATE_PACKAGE "cups" ... (已移除)
UPDATE_PACKAGE "istore" "linkease/istore" "main"

# ============================================
# 9. 4G/5G 模块 (已移除)
# ============================================
# 所有 4G/5G 相关包已删除，节省空间

# ============================================
# 10. PassWall 代理工具
# ============================================
UPDATE_PACKAGE "luci-app-passwall" "Openwrt-Passwall/openwrt-passwall" "main"
UPDATE_PACKAGE "xray-core v2ray-geodata v2ray-geosite sing-box chinadns-ng dns2socks hysteria ipt2socks naiveproxy shadowsocks-libev shadowsocks-rust shadowsocksr-libev simple-obfs tcping trojan-plus tuic-client v2ray-plugin xray-plugin geoview shadow-tls" "Openwrt-Passwall/openwrt-passwall-packages" "main" "pkg"

# ============================================
# 11. 配置清理 (Redmi AX5 NOWIFI 专属)
# ============================================
keywords_to_delete=(
	"xiaomi_ax3600" 
	"xiaomi_ax9000" 
	"xiaomi_ax1800" 
	"glinet" 
	"jdcloud_ax6600"
	"mr7350" 
	"uugamebooster" 
	"CONFIG_TARGET_INITRAMFS" 
	"ddns" 
	"kucat" 
	"bootstrap"
	"cmiot_ax18" 
	"qihoo_v6" 
	"zn_m2"
	# 禁用 WiFi 相关
	"wpad" 
	"hostapd"
	"kmod-ath11k"
	"kmod-cfg80211"
	"kmod-mac80211"
	# 禁用 4G/5G 相关
	"quectel"
	"qmodem"
	"ModemManager"
	"uqmi"
	"comgt"
	"kmod-mhi"
	"kmod-usb-serial"
	"kmod-usb-net-qmi"
	"kmod-usb-net-cdc-mbim"
	# 禁用 CUPS 相关
	"cups"
	"kmod-usb-printer"
	# 禁用 OpenClash
	"openclash"
	"mihomo"
	# 禁用 WOL (NOWIFI 不需要)
	"luci-app-wol"
	"luci-i18n-wol-zh-cn"
)

for keyword in "${keywords_to_delete[@]}"; do
	sed -i "/$keyword/d" ./.config 2>/dev/null
done

# ============================================
# 12. 软件包配置项 (写入 .config)
# ============================================
provided_config_lines=(
	# ZeroTier
	"CONFIG_PACKAGE_luci-app-zerotier=y"
	"CONFIG_PACKAGE_luci-i18n-zerotier-zh-cn=y"
	# 基础功能
	"CONFIG_PACKAGE_luci-app-poweroff=y"
	"CONFIG_PACKAGE_luci-i18n-poweroff-zh-cn=y"
	# iStore 依赖
	"CONFIG_PACKAGE_luci-lib-taskd=y"
	"CONFIG_PACKAGE_luci-lib-xterm=y"
	"CONFIG_PACKAGE_xterm=y"
	# 系统工具
	"CONFIG_PACKAGE_cpufreq=y"
	"CONFIG_PACKAGE_luci-app-cpufreq=y"
	"CONFIG_PACKAGE_luci-i18n-cpufreq-zh-cn=y"
	"CONFIG_PACKAGE_luci-app-ttyd=y"
	"CONFIG_PACKAGE_luci-i18n-ttyd-zh-cn=y"
	"CONFIG_PACKAGE_ttyd=y"
	"CONFIG_PACKAGE_luci-app-homeproxy=n"
	"CONFIG_PACKAGE_luci-i18n-homeproxy-zh-cn=n"
	"CONFIG_PACKAGE_luci-app-argon-config=y"
	"CONFIG_PACKAGE_nano=y"
	"CONFIG_BUSYBOX_CONFIG_LSUSB=y"
	"CONFIG_PACKAGE_luci-app-netspeedtest=y"
	"CONFIG_COREMARK_OPTIMIZE_O3=y"
	"CONFIG_COREMARK_ENABLE_MULTITHREADING=y"
	"CONFIG_COREMARK_NUMBER_OF_THREADS=6"
	"CONFIG_PACKAGE_luci-theme-design=y"
	"CONFIG_PACKAGE_luci-app-filetransfer=y"
	"CONFIG_PACKAGE_openssh-sftp-server=y"
	"CONFIG_PACKAGE_luci-app-frpc=y"
	"CONFIG_OPKG_USE_CURL=y"
	"CONFIG_PACKAGE_opkg=y"
	"CONFIG_USE_APK=n"
	"CONFIG_PACKAGE_luci-app-tailscale=y"
	"CONFIG_PACKAGE_luci-app-gecoosac=y"
	"CONFIG_PACKAGE_usbutils=y"
	"CONFIG_PACKAGE_luci-app-diskman=y"
	"CONFIG_PACKAGE_luci-i18n-diskman-zh-cn=y"
	"CONFIG_PACKAGE_luci-app-autoreboot=y"
	"CONFIG_PACKAGE_luci-i18n-autoreboot-zh-cn=y"
	"CONFIG_PACKAGE_luci-app-ddnsto=y"
	"CONFIG_PACKAGE_ddnsto=y"
	"CONFIG_PACKAGE_luci-app-store=y"
	"CONFIG_PACKAGE_luci-app-istorex=y"
	"CONFIG_PACKAGE_luci-app-quickstart=y"
	"CONFIG_PACKAGE_quickstart=y"
	"CONFIG_PACKAGE_luci-app-openclash=n"
	
	# DiskMan 依赖
	"CONFIG_PACKAGE_parted=y"
	"CONFIG_PACKAGE_blkid=y"
	"CONFIG_PACKAGE_e2fsprogs=y"
	"CONFIG_PACKAGE_block-mount=y"
	"CONFIG_PACKAGE_kmod-fs-ext4=y"
	
	# 修复缺失的依赖
	"CONFIG_PACKAGE_libparted=y"
	"CONFIG_PACKAGE_nikki=y"
	"CONFIG_PACKAGE_python3-pysocks=y"
	"CONFIG_PACKAGE_python3-unidecode=y"

	# ============================================
	# WiFi 禁用配置 (NOWIFI 版本)
	# ============================================
	"CONFIG_PACKAGE_hostapd-common=n"
	"CONFIG_PACKAGE_wpad-openssl=n"
	"CONFIG_PACKAGE_kmod-cfg80211=n"
	"CONFIG_PACKAGE_kmod-mac80211=n"
	"CONFIG_PACKAGE_kmod-ath11k=n"
	"CONFIG_PACKAGE_luci-app-wol=n"
	"CONFIG_PACKAGE_luci-i18n-wol-zh-cn=n"

	# ============================================
	# 4G/5G 禁用配置
	# ============================================
	"CONFIG_PACKAGE_quectel-CM=n"
	"CONFIG_PACKAGE_quectel-CM-5G=n"
	"CONFIG_PACKAGE_ModemManager=n"
	"CONFIG_PACKAGE_mmcli=n"
	"CONFIG_PACKAGE_uqmi=n"
	"CONFIG_PACKAGE_comgt=n"
	"CONFIG_PACKAGE_comgt-ncm=n"
	"CONFIG_PACKAGE_kmod-mhi-bus=n"
	"CONFIG_PACKAGE_kmod-mhi-net=n"
	"CONFIG_PACKAGE_kmod-mhi-wwan-ctrl=n"
	"CONFIG_PACKAGE_kmod-mhi-wwan-mbim=n"
	"CONFIG_PACKAGE_kmod-usb-serial=n"
	"CONFIG_PACKAGE_kmod-usb-serial-option=n"
	"CONFIG_PACKAGE_kmod-usb-serial-qualcomm=n"
	"CONFIG_PACKAGE_kmod-usb-net-qmi-wwan=n"
	"CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=n"
	"CONFIG_PACKAGE_luci-app-qmodem=n"
	"CONFIG_PACKAGE_luci-app-qmodem-sms=n"
	"CONFIG_PACKAGE_luci-app-qmodem-mwan=n"
	"CONFIG_PACKAGE_luci-app-modeminfo=n"
	"CONFIG_PACKAGE_luci-proto-3g=n"
	"CONFIG_PACKAGE_luci-proto-qmi=n"
	"CONFIG_PACKAGE_luci-proto-ncm=n"
	"CONFIG_PACKAGE_luci-proto-mbim=n"

	# ============================================
	# CUPS 禁用配置
	# ============================================
	"CONFIG_PACKAGE_cups=n"
	"CONFIG_PACKAGE_cups-bsd=n"
	"CONFIG_PACKAGE_cups-client=n"
	"CONFIG_PACKAGE_cups-filters=n"
	"CONFIG_PACKAGE_kmod-usb-printer=n"
	"CONFIG_PACKAGE_wqy-zenhei-font=n"
	"CONFIG_PACKAGE_dejavu-fonts-ttf=n"
	"CONFIG_PACKAGE_luci-i18n-cups-zh-cn=n"

	# ============================================
	# OpenClash 禁用配置
	# ============================================
	"CONFIG_PACKAGE_luci-app-openclash=n"
	"CONFIG_PACKAGE_mihomo=n"
	"CONFIG_PACKAGE_luci-app-nikki=n"

	# ============================================
	# USB 存储支持 (Redmi AX5 USB 2.0)
	# ============================================
	"CONFIG_PACKAGE_kmod-usb2=y"
	"CONFIG_PACKAGE_kmod-usb-storage=y"
	"CONFIG_PACKAGE_kmod-usb-storage-uas=y"
	"CONFIG_PACKAGE_kmod-fs-ext4=y"
	"CONFIG_PACKAGE_kmod-fs-exfat=y"
	"CONFIG_PACKAGE_kmod-fs-ntfs3=y"
	"CONFIG_PACKAGE_kmod-fs-vfat=y"
	"CONFIG_PACKAGE_luci-app-samba4=y"
	"CONFIG_PACKAGE_samba4-server=y"
	"CONFIG_PACKAGE_autosamba=y"
)

# ============================================
# 13. Redmi AX5 NOWIFI 专属配置
# ============================================
provided_config_lines+=(
	# NSS 加速
	"CONFIG_PACKAGE_sqm-scripts-nss=y"
	# 网络优化
	"CONFIG_PACKAGE_iptables-mod-extra=y"
	"CONFIG_PACKAGE_ip6tables-nft=y"
	"CONFIG_PACKAGE_ip6tables-mod-fullconenat=y"
	"CONFIG_PACKAGE_iptables-mod-fullconenat=y"
	"CONFIG_PACKAGE_libip4tc=y"
	"CONFIG_PACKAGE_libip6tc=y"
	# 网络工具
	"CONFIG_PACKAGE_htop=y"
	"CONFIG_PACKAGE_tcpdump=y"
	"CONFIG_PACKAGE_openssl-util=y"
	"CONFIG_PACKAGE_qrencode=y"
	"CONFIG_PACKAGE_smartmontools-drivedb=y"
	# 默认设置
	"CONFIG_PACKAGE_default-settings=y"
	"CONFIG_PACKAGE_default-settings-chn=y"
	# 网络模块
	"CONFIG_PACKAGE_iptables-mod-conntrack-extra=y"
	"CONFIG_PACKAGE_kmod-br-netfilter=y"
	"CONFIG_PACKAGE_kmod-ip6tables=y"
	"CONFIG_PACKAGE_kmod-ipt-conntrack=y"
	"CONFIG_PACKAGE_kmod-ipt-extra=y"
	"CONFIG_PACKAGE_kmod-ipt-nat=y"
	"CONFIG_PACKAGE_kmod-ipt-nat6=y"
	"CONFIG_PACKAGE_kmod-ipt-physdev=y"
	"CONFIG_PACKAGE_kmod-nf-ipt6=y"
	"CONFIG_PACKAGE_kmod-nf-ipvs=y"
	"CONFIG_PACKAGE_kmod-nf-nat6=y"
	"CONFIG_PACKAGE_kmod-dummy=y"
	"CONFIG_PACKAGE_kmod-veth=y"
	# FRP 服务端
	"CONFIG_PACKAGE_luci-app-frps=y"
	# QuickFile
	"CONFIG_PACKAGE_luci-app-quickfile=y"
	# PassWall
	"CONFIG_PACKAGE_luci-app-passwall=y"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y"
	# USB 网络基础驱动 (保留最基础的)
	"CONFIG_PACKAGE_kmod-usb-net=y"
	"CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y"
	"CONFIG_PACKAGE_kmod-usb-net-rndis=y"
	"CONFIG_PACKAGE_kmod-usb-acm=y"
	"CONFIG_PACKAGE_kmod-usb-ohci=y"
)

# 将配置项追加到 .config 文件
for line in "${provided_config_lines[@]}"; do
	echo "$line" >> .config
done

# ============================================
# 14. 内核补丁与设备树修复 (Redmi AX5 NOWIFI)
# ============================================
rm -f ./target/linux/qualcommax/patches-6.12/0083-v6.11-arm64-dts-qcom-ipq6018-add-sdhci-node.patch

# 创建 Redmi AX5 NOWIFI 设备树配置
mkdir -p ./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom
cat > ./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-redmi-ax5-nowifi.dtsi << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
#include "ipq6018.dtsi"

/ {
	model = "Xiaomi Redmi AX5 NOWIFI";
	compatible = "xiaomi,redmi-ax5-nowifi", "qcom,ipq6018";

	memory@40000000 {
		device_type = "memory";
		reg = <0x0 0x40000000 0x0 0x20000000>;
	};

	aliases {
		label-mac-device = &gmac0;
		led-boot = &led_status_yellow;
		led-failsafe = &led_status_red;
		led-running = &led_status_blue;
		led-upgrade = &led_status_yellow;
	};

	chosen {
		bootargs = "console=ttyMSM0,115200n8";
	};
};

&gmac0 {
	status = "okay";
	phy-mode = "sgmii";
};

&gmac1 {
	status = "okay";
	phy-mode = "sgmii";
};

/* WiFi 节点 - NOWIFI 版本禁用 */
&wifi0 {
	status = "disabled";
};

&wifi1 {
	status = "disabled";
};

/* LED 配置 */
&led_status_blue {
	label = "redmi-ax5:blue:status";
};

&led_status_yellow {
	label = "redmi-ax5:yellow:status";
};

&led_status_red {
	label = "redmi-ax5:red:status";
};

/* USB 2.0 支持 */
&usb3_0 {
	status = "okay";
};

&usb3_0_phy {
	status = "okay";
};
EOF

# ============================================
# 15. 代码修复
# ============================================
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \; 2>/dev/null
sed -i '/\/usr\/bin\/zsh/d' package/base-files/files/etc/profile 2>/dev/null
find ./ -name "cascade.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null
find ./ -name "dark.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null
find ./ -name "cascade.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null
find ./ -name "dark.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null

# ============================================
# 16. UCI 默认值设置 & 自动化脚本
# ============================================

# 基础脚本
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" "package/base-files/files/etc/uci-defaults/99_ttyd-nopass" 2>/dev/null || true
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" "package/base-files/files/etc/uci-defaults/99_set_argon_primary" 2>/dev/null || true
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" "package/base-files/files/etc/uci-defaults/99_dropbear_setup" 2>/dev/null || true

# 4G/5G 模块脚本已移除 (不需要)

# ============================================
# CUPS 汉化脚本已移除 (不需要)
# ============================================

# ============================================
# 17. Golang 编译器更新
# ============================================
GOLANG_REPO="https://github.com/sbwml/packages_lang_golang"
GOLANG_BRANCH="25.x"
if [[ -d ./feeds/packages/lang/golang ]]; then 
	rm -rf ./feeds/packages/lang/golang
	git clone $GOLANG_REPO -b $GOLANG_BRANCH ./feeds/packages/lang/golang 2>/dev/null
fi

# ============================================
# 完成提示
# ============================================
echo "============================================"
echo "DIY 脚本执行完毕！"
echo "设备: Redmi AX5 NOWIFI (IPQ6018)"
echo "已包含功能:"
echo "  - 默认 IP: 192.168.5.1"
echo "  - WiFi 功能: 已禁用"
echo "  - 4G/5G 模块: 已禁用"
echo "  - CUPS 打印服务: 已禁用"
echo "  - OpenClash: 已禁用"
echo "  - PassWall 代理工具"
echo "  - Tailscale/ZeroTier 组网"
echo "  - DiskMan 磁盘管理"
echo "  - Samba 文件共享"
echo "  - USB 2.0 存储支持"
echo "  - NSS 硬件加速"
echo "============================================"
