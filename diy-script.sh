#!/bin/bash

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
# 4. 科学上网工具集
# ============================================
UPDATE_PACKAGE "xray-core xray-plugin dns2tcp dns2socks haproxy hysteria \
naiveproxy shadowsocks-rust v2ray-core v2ray-geodata v2ray-geoview v2ray-plugin \
tuic-client chinadns-ng ipt2socks tcping trojan-plus simple-obfs shadowsocksr-libev \
luci-app-passwall smartdns luci-app-smartdns v2dat mosdns luci-app-mosbnb \
taskd luci-lib-xterm luci-lib-taskd luci-app-ssr-plus luci-app-passwall2 \
luci-app-store quickstart luci-app-quickstart luci-app-istorex luci-app-cloudflarespeedtest \
luci-theme-argon netdata luci-app-netdata lucky luci-app-lucky luci-app-openclash mihomo \
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
# 8. 服务工具
# ============================================
UPDATE_PACKAGE "frp" "https://github.com/ysuolmai/openwrt-frp.git" "master"
UPDATE_PACKAGE "ddnsto" "kenzok8/openwrt-packages" "master" "pkg"
UPDATE_PACKAGE "cups" "https://github.com/op4packages/openwrt-cups.git" "master" "pkg"
UPDATE_PACKAGE "istore" "linkease/istore" "main"

# ============================================
# 9. 4G/5G 模块完整支持
# ============================================

# 9.1 内核驱动层
UPDATE_PACKAGE "kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-qualcomm \
kmod-usb-net kmod-usb-net-qmi-wwan kmod-usb-net-cdc-ether kmod-usb-net-rndis \
kmod-usb-net-sierrawireless kmod-usb-acm kmod-usb-ohci kmod-usb2 kmod-usb3 \
kmod-mhi-bus kmod-mhi-net kmod-mhi-wwan-ctrl kmod-mhi-wwan-mbim \
kmod-usb-net-cdc-mbim kmod-usb-net-huawei-cdc-ncm" "openwrt/openwrt" "openwrt-24.10" "pkg"

# 9.2 拨号工具层
UPDATE_PACKAGE "quectel-CM quectel-CM-5G" "mdsdtech/5G-Modem-Packages" "main" "pkg"
UPDATE_PACKAGE "ModemManager uqmi comgt comgt-ncm mmcli" "openwrt/packages" "openwrt-24.10" "pkg"

# 9.3 LuCI 管理界面
UPDATE_PACKAGE "luci-app-qmodem luci-app-qmodem-sms luci-app-qmodem-mwan" "FUjr/QModem" "main" "pkg"
UPDATE_PACKAGE "luci-app-modeminfo" "4IceG/luci-app-modeminfo" "main"
UPDATE_PACKAGE "luci-proto-3g luci-proto-qmi luci-proto-ncm luci-proto-mbim" "openwrt/luci" "openwrt-24.10" "pkg"

# ============================================
# 10. PassWall 代理工具
# ============================================
UPDATE_PACKAGE "luci-app-passwall" "Openwrt-Passwall/openwrt-passwall" "main"
UPDATE_PACKAGE "xray-core v2ray-geodata v2ray-geosite sing-box chinadns-ng dns2socks hysteria ipt2socks naiveproxy shadowsocks-libev shadowsocks-rust shadowsocksr-libev simple-obfs tcping trojan-plus tuic-client v2ray-plugin xray-plugin geoview shadow-tls" "Openwrt-Passwall/openwrt-passwall-packages" "main" "pkg"

# ============================================
# 11. 修复依赖缺失问题
# ============================================

echo "[开始] 修复 qmodem 及 4G/5G 包依赖..."
QMODEM_MAKEFILES=$(find package -name "Makefile" -path "*/qmodem/*" 2>/dev/null)
if [ -n "$QMODEM_MAKEFILES" ]; then
    for makefile in $QMODEM_MAKEFILES; do
        echo "[修复] 处理文件: $makefile"
        sed -i 's/+kmod-mhi-wwan/+kmod-mhi-wwan-ctrl +kmod-mhi-wwan-mbim/g' "$makefile"
        sed -i 's/+quectel-CM-5G/+quectel-cm/g' "$makefile"
    done
    echo "[完成] qmodem 依赖修复"
else
    echo "[提示] 未找到 qmodem Makefile"
fi

MM_MAKEFILES=$(find package -name "Makefile" -path "*ModemManager*" 2>/dev/null)
for makefile in $MM_MAKEFILES; do
    sed -i 's/+libusb-1.0/+libusb-1.0 +libglib2.0 +libudev-zero/g' "$makefile" 2>/dev/null
done

# ============================================
# 12. 配置清理
# ============================================
keywords_to_delete=(
	"xiaomi_ax3600" "xiaomi_ax9000" "xiaomi_ax1800" "glinet" "jdcloud_ax6600"
	"mr7350" "uugamebooster" "luci-app-wol" "luci-i18n-wol-zh-cn"
	"CONFIG_TARGET_INITRAMFS" "ddns" "kucat" "bootstrap"
)
[[ $FIRMWARE_TAG == *"NOWIFI"* ]] && keywords_to_delete+=("wpad" "hostapd" "redmi_ax5")
[[ $FIRMWARE_TAG != *"EMMC"* ]] && keywords_to_delete+=("samba" "autosamba" "disk")
[[ $FIRMWARE_TAG == *"EMMC"* ]] && keywords_to_delete+=("cmiot_ax18" "qihoo_v6" "redmi_ax5" "zn_m2")

for keyword in "${keywords_to_delete[@]}"; do
	sed -i "/$keyword/d" ./.config 2>/dev/null
done

# ============================================
# 13. 软件包配置项 (写入 .config)
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
	"CONFIG_PACKAGE_luci-app-openclash=y"
	
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
	# 4G/5G 模块配置
	# ============================================
	"CONFIG_PACKAGE_kmod-usb-serial=y"
	"CONFIG_PACKAGE_kmod-usb-serial-option=y"
	"CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y"
	"CONFIG_PACKAGE_kmod-usb-acm=y"
	"CONFIG_PACKAGE_kmod-usb-net=y"
	"CONFIG_PACKAGE_kmod-usb-net-qmi-wwan=y"
	"CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y"
	"CONFIG_PACKAGE_kmod-usb-net-rndis=y"
	"CONFIG_PACKAGE_kmod-usb-net-sierrawireless=y"
	"CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=y"
	"CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm=y"
	"CONFIG_PACKAGE_kmod-mhi-bus=y"
	"CONFIG_PACKAGE_kmod-mhi-net=y"
	"CONFIG_PACKAGE_kmod-mhi-wwan-ctrl=y"
	"CONFIG_PACKAGE_kmod-mhi-wwan-mbim=y"
	"CONFIG_PACKAGE_quectel-CM=y"
	"CONFIG_PACKAGE_quectel-CM-5G=y"
	"CONFIG_PACKAGE_ModemManager=y"
	"CONFIG_PACKAGE_mmcli=y"
	"CONFIG_PACKAGE_uqmi=y"
	"CONFIG_PACKAGE_comgt=y"
	"CONFIG_PACKAGE_comgt-ncm=y"
	"CONFIG_PACKAGE_chat=y"
	"CONFIG_PACKAGE_ppp=y"
	"CONFIG_PACKAGE_kmod-ppp=y"
	"CONFIG_PACKAGE_luci-proto-3g=y"
	"CONFIG_PACKAGE_luci-proto-qmi=y"
	"CONFIG_PACKAGE_luci-proto-ncm=y"
	"CONFIG_PACKAGE_luci-proto-mbim=y"
	"CONFIG_PACKAGE_luci-app-qmodem=y"
	"CONFIG_PACKAGE_luci-app-qmodem-sms=y"
	"CONFIG_PACKAGE_luci-app-qmodem-mwan=y"
	"CONFIG_PACKAGE_luci-app-modeminfo=y"
	"CONFIG_PACKAGE_luci-i18n-qmodem-zh-cn=y"
	"CONFIG_PACKAGE_luci-i18n-modeminfo-zh-cn=y"

	# ============================================
	# CUPS 打印服务及汉化配置
	# ============================================
	"CONFIG_PACKAGE_cups=y"
	"CONFIG_PACKAGE_cups-bsd=y"
	"CONFIG_PACKAGE_cups-client=y"
	"CONFIG_PACKAGE_cups-filters=y"
	"CONFIG_PACKAGE_kmod-usb-printer=y"
	"CONFIG_PACKAGE_wqy-zenhei-font=y"
	"CONFIG_PACKAGE_dejavu-fonts-ttf=y"
	"CONFIG_PACKAGE_luci-i18n-cups-zh-cn=y"
)

DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"

# ============================================
# 14. NOWIFI 版本专属配置
# ============================================
if [[ $FIRMWARE_TAG == *"NOWIFI"* ]]; then
	provided_config_lines+=(
		"CONFIG_PACKAGE_hostapd-common=n"
		"CONFIG_PACKAGE_wpad-openssl=n"
		"CONFIG_PACKAGE_kmod-usb3=y"
		"CONFIG_PACKAGE_kmod-usb-storage=y"
		"CONFIG_PACKAGE_kmod-usb-storage-uas=y"
		"CONFIG_PACKAGE_kmod-fs-ext4=y"
		"CONFIG_PACKAGE_kmod-fs-exfat=y"
		"CONFIG_PACKAGE_kmod-fs-ntfs3=y"
		"CONFIG_PACKAGE_kmod-fs-vfat=y"
		"CONFIG_PACKAGE_cups=y"
		"CONFIG_PACKAGE_cups-bsd=y"
		"CONFIG_PACKAGE_cups-client=y"
		"CONFIG_PACKAGE_kmod-usb-printer=y"
	)
else
	provided_config_lines+=(
		"CONFIG_PACKAGE_kmod-usb-net=y"
		"CONFIG_PACKAGE_kmod-usb-net-rndis=y"
		"CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y"
		"CONFIG_PACKAGE_usbutils=y"
		"CONFIG_PACKAGE_kmod-usb-acm=y"
		"CONFIG_PACKAGE_kmod-usb-ehci=y"
		"CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm=y"
		"CONFIG_PACKAGE_kmod-usb-net-asix-ax88179=y"
		"CONFIG_PACKAGE_kmod-usb-net-rtl8152=y"
		"CONFIG_PACKAGE_kmod-usb-net-sierrawireless=y"
		"CONFIG_PACKAGE_kmod-usb-ohci=y"
		"CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y"
		"CONFIG_PACKAGE_kmod-usb-storage=y"
		"CONFIG_PACKAGE_kmod-usb2=y"
	)
fi

# ============================================
# 15. EMMC 版本额外配置
# ============================================
[[ $FIRMWARE_TAG == *"EMMC"* ]] && provided_config_lines+=(
	"CONFIG_PACKAGE_luci-app-podman=y"
	"CONFIG_PACKAGE_podman=y"
	"CONFIG_PACKAGE_luci-app-openlist2=y"
	"CONFIG_PACKAGE_luci-i18n-openlist2-zh-cn=y"
	"CONFIG_PACKAGE_luci-app-autoreboot=y"
	"CONFIG_PACKAGE_luci-i18n-autoreboot-zh-cn=y"
	"CONFIG_PACKAGE_cups=y"
	"CONFIG_PACKAGE_cups-bsd=y"
	"CONFIG_PACKAGE_cups-client=y"
	"CONFIG_PACKAGE_kmod-usb-printer=y"
	"CONFIG_PACKAGE_iptables-mod-extra=y"
	"CONFIG_PACKAGE_ip6tables-nft=y"
	"CONFIG_PACKAGE_ip6tables-mod-fullconenat=y"
	"CONFIG_PACKAGE_iptables-mod-fullconenat=y"
	"CONFIG_PACKAGE_libip4tc=y"
	"CONFIG_PACKAGE_libip6tc=y"
	"CONFIG_PACKAGE_luci-app-passwall=y"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=n"
	"CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y"
	"CONFIG_PACKAGE_htop=y"
	"CONFIG_PACKAGE_tcpdump=y"
	"CONFIG_PACKAGE_openssl-util=y"
	"CONFIG_PACKAGE_qrencode=y"
	"CONFIG_PACKAGE_smartmontools-drivedb=y"
	"CONFIG_PACKAGE_usbutils=y"
	"CONFIG_PACKAGE_default-settings=y"
	"CONFIG_PACKAGE_default-settings-chn=y"
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
	"CONFIG_PACKAGE_luci-app-frps=y"
	"CONFIG_PACKAGE_luci-app-samba4=y"
	"CONFIG_PACKAGE_luci-app-openclash=y"
	"CONFIG_PACKAGE_luci-app-quickfile=y"
)

[[ $FIRMWARE_TAG == "IPQ"* ]] && provided_config_lines+=("CONFIG_PACKAGE_sqm-scripts-nss=y")

# 将配置项追加到 .config 文件
for line in "${provided_config_lines[@]}"; do
	echo "$line" >> .config
done

# ============================================
# 16. 内核补丁与设备树修复
# ============================================
rm -f ./target/linux/qualcommax/patches-6.12/0083-v6.11-arm64-dts-qcom-ipq6018-add-sdhci-node.patch

mkdir -p ./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom
cat > ./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-nowifi.dtsi << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
#include "ipq6018.dtsi"

/ {
	model = "Qualcomm Technologies, Inc. IPQ6018-512M-NOWIFI";
	compatible = "qcom,ipq6018";

	memory@40000000 {
		device_type = "memory";
		reg = <0x0 0x40000000 0x0 0x20000000>;
	};
};

&wifi0 {
	status = "disabled";
};

&wifi1 {
	status = "disabled";
};
EOF

# ============================================
# 17. 代码修复
# ============================================
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \; 2>/dev/null
sed -i '/\/usr\/bin\/zsh/d' package/base-files/files/etc/profile 2>/dev/null
find ./ -name "cascade.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null
find ./ -name "dark.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null
find ./ -name "cascade.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null
find ./ -name "dark.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null

# ============================================
# 18. UCI 默认值设置 & 自动化脚本
# ============================================

# 基础脚本
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" "package/base-files/files/etc/uci-defaults/99_ttyd-nopass" 2>/dev/null || true
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" "package/base-files/files/etc/uci-defaults/99_set_argon_primary" 2>/dev/null || true
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" "package/base-files/files/etc/uci-defaults/99_dropbear_setup" 2>/dev/null || true

if [[ $FIRMWARE_TAG == *"EMMC"* ]]; then
	install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_nginx_setup.sh" "package/base-files/files/etc/uci-defaults/99_nginx_setup" 2>/dev/null || true
fi

# 4G/5G 模块自动模式切换脚本
cat > package/base-files/files/etc/uci-defaults/99_4g_mode_switch << 'EOF'
#!/bin/sh
log() { echo "[4G-INIT] $1"; }

switch_quectel_mode() {
    if lsusb | grep -q "2c7c:"; then
        log "检测到 Quectel 模块，尝试切换至 ECM/QMI 模式..."
        for tty in /dev/ttyUSB*; do
            if [ -c "$tty" ]; then
                echo -e "AT+QCFG=\"usbnet\",1\r" > "$tty" 2>/dev/null
                sleep 1
                break
            fi
        done
        log "模式切换指令已发送"
    else
        log "未检测到 Quectel 模块"
    fi
}

(sleep 15 && switch_quectel_mode) &
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99_4g_mode_switch

# ============================================
# CUPS 汉化配置脚本
# ============================================
cat > package/base-files/files/etc/uci-defaults/99_cups_i18n << 'EOF'
#!/bin/sh

log() { echo "[CUPS-I18N] $1"; }

configure_cups_language() {
    local CUPS_CONF="/etc/cups/cupsd.conf"
    
    if [ -f "$CUPS_CONF" ]; then
        log "配置 CUPS 中文语言..."
        
        # 备份原配置
        cp -f "$CUPS_CONF" "${CUPS_CONF}.bak" 2>/dev/null
        
        # 设置默认语言为中文
        if grep -q "^DefaultLanguage" "$CUPS_CONF"; then
            sed -i 's/^DefaultLanguage.*/DefaultLanguage zh_CN/' "$CUPS_CONF"
        else
            sed -i '/^ServerName/a DefaultLanguage zh_CN' "$CUPS_CONF"
        fi
        
        # 允许局域网访问
        sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' "$CUPS_CONF"
        sed -i 's/Listen \/run\/cups\/cups.sock/Listen \/run\/cups\/cups.sock\nListen 0.0.0.0:631/' "$CUPS_CONF"
        
        # 配置访问权限
        sed -i '/<Location \/>/,/<\/Location>/s/Allow from.*/Allow from all/' "$CUPS_CONF" 2>/dev/null
        sed -i '/<Location \/admin>/,/<\/Location>/s/Allow from.*/Allow from all/' "$CUPS_CONF" 2>/dev/null
        
        # 启用并重启服务
        /etc/init.d/cupsd enable 2>/dev/null
        /etc/init.d/cupsd restart 2>/dev/null
        
        log "CUPS 汉化配置完成"
    else
        log "警告：未找到 CUPS 配置文件"
    fi
}

# 设置 LuCI 默认语言为中文
configure_luci_language() {
    local LUCI_CONF="/etc/config/luci"
    if [ -f "$LUCI_CONF" ]; then
        log "配置 LuCI 中文语言..."
        uci set luci.main.lang='zh_cn' 2>/dev/null && uci commit luci 2>/dev/null
    fi
}

# 延迟执行，等待系统初始化完成
(sleep 20 && configure_cups_language && configure_luci_language) &

exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99_cups_i18n

# ============================================
# 19. Golang 编译器更新
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
echo "已包含功能:"
echo "  - 完整 4G/5G 模块支持 (USB/PCIe)"
echo "  - CUPS 打印服务 + 中文汉化"
echo "  - PassWall/OpenClash 代理工具"
echo "  - Tailscale/ZeroTier 组网"
echo "  - DiskMan 磁盘管理"
echo "  - Podman 容器 (EMMC 版本)"
echo "============================================"
