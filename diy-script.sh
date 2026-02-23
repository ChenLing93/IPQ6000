#!/bin/bash
# ============================================
# OpenWrt IPQ6018 DIY 自动配置脚本
# 平台: Qualcomm IPQ6018 (NOWIFI/EMMC 版本)
# 内核: 6.12
# ============================================

# 1. 修改默认 IP 地址
sed -i 's/192.168.5.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 2. 软件包更新函数定义
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4

	# 清理旧的包 - 删除 feeds 中已存在的同名包
	read -ra PKG_NAMES <<< "$PKG_NAME"
	for NAME in "${PKG_NAMES[@]}"; do
		rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" -prune)
	done

	# 克隆仓库 - 从 GitHub 获取软件包源码
	if [[ $PKG_REPO == http* ]]; then
		local REPO_NAME=$(echo $PKG_REPO | awk -F '/' '{gsub(/\.git$/, "", $NF); print $NF}')
		git clone --depth=1 --single-branch --branch $PKG_BRANCH "$PKG_REPO" package/$REPO_NAME
	else
		local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)
		git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" package/$REPO_NAME
	fi

	# 根据 PKG_SPECIAL 处理包
	case "$PKG_SPECIAL" in
		"pkg")
			# pkg 模式: 从仓库中提取多个子包到 package 根目录
			for NAME in "${PKG_NAMES[@]}"; do
				echo "moving $NAME"
				cp -rf $(find ./package/$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$NAME*" -prune) ./package/
			done
			rm -rf ./package/$REPO_NAME/
			;;
		"name")
			# name 模式: 重命名仓库目录为指定包名
			mv -f ./package/$REPO_NAME ./package/$PKG_NAME
			;;
	esac
}

# ============================================
# 3. 基础工具安装
# ============================================
UPDATE_PACKAGE "luci-app-poweroff" "esirplayground/luci-app-poweroff" "master"
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"
UPDATE_PACKAGE "openwrt-gecoosac" "lwb1978/openwrt-gecoosac" "main"
#UPDATE_PACKAGE "luci-app-homeproxy" "immortalwrt/homeproxy" "master"
#UPDATE_PACKAGE "luci-app-ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "luci-app-openlist2" "sbwml/luci-app-openlist2" "main"

# ============================================
# 4. 科学上网工具集
# ============================================
UPDATE_PACKAGE "xray-core xray-plugin dns2tcp dns2socks haproxy hysteria \
naiveproxy shadowsocks-rust v2ray-core v2ray-geodata v2ray-geoview v2ray-plugin \
tuic-client chinadns-ng ipt2socks tcping trojan-plus simple-obfs shadowsocksr-libev \
luci-app-passwall smartdns luci-app-smartdns v2dat mosdns luci-app-mosdns \
taskd luci-lib-xterm luci-lib-taskd luci-app-ssr-plus luci-app-passwall2 \
luci-app-store quickstart luci-app-quickstart luci-app-istorex luci-app-cloudflarespeedtest \
luci-theme-argon netdata luci-app-netdata lucky luci-app-lucky luci-app-openclash mihomo \
luci-app-nikki luci-app-vlmcsd vlmcsd" "kenzok8/small-package" "main" "pkg"

# ============================================
# 5. 网络测速工具
# ============================================
UPDATE_PACKAGE "luci-app-netspeedtest" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"
UPDATE_PACKAGE "speedtest-cli" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"
#UPDATE_PACKAGE "luci-app-adguardhome" "https://github.com/ysuolmai/luci-app-adguardhome.git" "master"

# ============================================
# 6. 容器与文件工具
# ============================================
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"
UPDATE_PACKAGE "openwrt-podman" "https://github.com/breeze303/openwrt-podman" "main"
UPDATE_PACKAGE "luci-app-quickfile" "https://github.com/sbwml/luci-app-quickfile" "main"
sed -i 's|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-$(ARCH_PACKAGES) $(1)/usr/bin/quickfile|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-aarch64_generic $(1)/usr/bin/quickfile|' package/luci-app-quickfile/quickfile/Makefile

# ============================================
# 7. 磁盘管理工具
# ============================================
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname luci-app-diskman -prune)
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname parted -prune)
mkdir -p package/luci-app-diskman && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -O package/luci-app-diskman/Makefile
sed -i 's/fs-ntfs /fs-ntfs3 /g' package/luci-app-diskman/Makefile
sed -i '/ntfs-3g-utils /d' package/luci-app-diskman/Makefile
mkdir -p package/parted && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O package/parted/Makefile

# ============================================
# 8. 服务工具
# ============================================
UPDATE_PACKAGE "frp" "https://github.com/ysuolmai/openwrt-frp.git" "master"
UPDATE_PACKAGE "ddnsto" "kenzok8/openwrt-packages" "master" "pkg"
UPDATE_PACKAGE "cups" "https://github.com/op4packages/openwrt-cups.git" "master" "pkg"
UPDATE_PACKAGE "istore" "linkease/istore" "main"

# ============================================
# 9. 5G 调制解调器工具
# ============================================
#UPDATE_PACKAGE "luci-app-qmodem luci-app-qmodem-sms luci-app-qmodem-mwan" "FUjr/QModem" "main" "pkg"
UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main" "name"

# ============================================
# 修复依赖缺失问题
# ============================================

# 修复 qmodem 包在内核 6.12 下的依赖问题
echo "[开始] 修复 qmodem 包依赖..."
QMODEM_MAKEFILES=$(find package -name "Makefile" -path "*/qmodem/*" 2>/dev/null)
if [ -n "$QMODEM_MAKEFILES" ]; then
    echo "[找到] qmodem Makefile 文件:"
    echo "$QMODEM_MAKEFILES"
    for makefile in $QMODEM_MAKEFILES; do
        echo "[修复] 处理文件: $makefile"
        # 修复 MHI 驱动依赖
        sed -i 's/+kmod-mhi-wwan/+kmod-mhi-wwan-ctrl +kmod-mhi-wwan-mbim/g' "$makefile"
        # 修复 quectel-CM-5G 依赖（移除或替换为正确的包名）
        sed -i 's/+quectel-CM-5G/+quectel-cm/g' "$makefile"
        # 显示修复后的内容（仅相关行）
        echo "[检查] $makefile 的 DEPENDS 行:"
        grep -n "DEPENDS" "$makefile" | grep -E "mhi-wwan|quectel"
    done
    echo "[完成] 已修复 qmodem 包的依赖声明"
else
    echo "[警告] 未找到 qmodem Makefile 文件"
    # 尝试显示 package 目录结构
    echo "[调试] 搜索 qmodem 目录:"
    find package -type d -name "*qmodem*" 2>/dev/null || echo "未找到 qmodem 目录"
fi

# ============================================
# 10. PassWall 代理工具
# ============================================
UPDATE_PACKAGE "luci-app-passwall" "Openwrt-Passwall/openwrt-passwall" "main"
UPDATE_PACKAGE "xray-core v2ray-geodata v2ray-geosite sing-box chinadns-ng dns2socks hysteria ipt2socks naiveproxy shadowsocks-libev shadowsocks-rust shadowsocksr-libev simple-obfs tcping trojan-plus tuic-client v2ray-plugin xray-plugin geoview shadow-tls" "Openwrt-Passwall/openwrt-passwall-packages" "main" "pkg"

# ============================================
# 11. 移远 5G 拨号工具
# ============================================
UPDATE_PACKAGE "quectel-CM-5G" "mdsdtech/5G-Modem-Packages" "main" "pkg"

# ============================================
# 12. 配置清理 - 删除不需要的软件包
# ============================================
keywords_to_delete=(
	"xiaomi_ax3600"
	"xiaomi_ax9000"
	"xiaomi_ax1800"
	"glinet"
	"jdcloud_ax6600"
	"mr7350"
	"uugamebooster"
	"luci-app-wol"
	"luci-i18n-wol-zh-cn"
	"CONFIG_TARGET_INITRAMFS"
	"ddns"
	"mihomo"
	"kucat"
	"bootstrap"
	"vlmcsd"
	"luci-app-vlmcsd"
)
[[ $FIRMWARE_TAG == *"NOWIFI"* ]] && keywords_to_delete+=("wpad" "hostapd")
[[ $FIRMWARE_TAG != *"EMMC"* ]] && keywords_to_delete+=("samba" "autosamba" "disk")
[[ $FIRMWARE_TAG == *"EMMC"* ]] && keywords_to_delete+=("cmiot_ax18" "qihoo_v6" "redmi_ax5" "zn_m2")

for keyword in "${keywords_to_delete[@]}"; do
	sed -i "/$keyword/d" ./.config
done

# ============================================
# 13. 软件包配置项 (写入 .config)
# ============================================
provided_config_lines=(
	"CONFIG_PACKAGE_luci-app-zerotier=y"
	"CONFIG_PACKAGE_luci-i18n-zerotier-zh-cn=y"
	# "CONFIG_PACKAGE_luci-app-adguardhome=y"
	# "CONFIG_PACKAGE_luci-i18n-adguardhome-zh-cn=y"
	"CONFIG_PACKAGE_luci-app-poweroff=y"
	"CONFIG_PACKAGE_luci-i18n-poweroff-zh-cn=y"
	"CONFIG_PACKAGE_cpufreq=y"
	"CONFIG_PACKAGE_luci-app-cpufreq=y"
	"CONFIG_PACKAGE_luci-i18n-cpufreq-zh-cn=y"
	"CONFIG_PACKAGE_luci-app-ttyd=y"
	"CONFIG_PACKAGE_luci-i18n-ttyd-zh-cn=y"
	"CONFIG_PACKAGE_ttyd=y"
	#"CONFIG_PACKAGE_luci-app-homeproxy=y"
	#"CONFIG_PACKAGE_luci-i18n-homeproxy-zh-cn=y"
	#"CONFIG_PACKAGE_luci-app-ddns-go=y"
	#"CONFIG_PACKAGE_luci-i18n-ddns-go-zh-cn=y"
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
	"CONFIG_PACKAGE_luci-app-qmodem=y"
	"CONFIG_PACKAGE_luci-app-qmodem-sms=y"
	"CONFIG_PACKAGE_luci-app-qmodem-mwan=y"
	"CONFIG_PACKAGE_kmod-usb-serial=y"
	"CONFIG_PACKAGE_kmod-usb-serial-option=y"
	"CONFIG_PACKAGE_kmod-usb-serial-wwan=y"
	"CONFIG_PACKAGE_kmod-usb-net=y"
	"CONFIG_PACKAGE_kmod-usb-net-qmi-wwan=y"
	"CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=y"
	# PCIe 5G 模组支持 - 使用内核6.12内置的MHI驱动
	"CONFIG_PACKAGE_kmod-mhi-bus=y" # MHI 总线核心
	"CONFIG_PACKAGE_kmod-mhi-wwan-ctrl=y"
	"CONFIG_PACKAGE_kmod-mhi-wwan-mbim=y"
	"CONFIG_PACKAGE_kmod-wwan=y" # WWAN 通用框架
	"CONFIG_PACKAGE_kmod-pci=y" # PCIe 支持
	# PCIe 5G 拨号工具
	"CONFIG_PACKAGE_quectel-CM-5G=y"
	# QMI/MBIM 协议支持
	"CONFIG_PACKAGE_libqmi=y"
	"CONFIG_PACKAGE_libmbim=y"
	"CONFIG_PACKAGE_uqmi=y"
	# QModem 依赖工具
	"CONFIG_PACKAGE_uqmi=y"
	"CONFIG_PACKAGE_quectel-cm=y"
	"CONFIG_PACKAGE_sms-tool=y"

	# ============================================
	# NSS 网络加速支持 (解决 qca-nss-ecm 编译错误)
	# ============================================
	"CONFIG_PACKAGE_kmod-qca-nss-drv=y"           # NSS 驱动核心
	"CONFIG_PACKAGE_kmod-qca-nss-ecm=y"           # NSS 连接管理器
	"CONFIG_PACKAGE_kmod-qca-nss-dp=y"            # NSS 数据平面加速
	"CONFIG_PACKAGE_kmod-qca-nss-crypto=y"        # NSS 加密加速
	"CONFIG_PACKAGE_kmod-qca-ssdk=y"              # NSS 交换机驱动
	"CONFIG_PACKAGE_kmod-qca-nss-macsec=y"        # NSS MACsec 加密
	"CONFIG_PACKAGE_kmod-qca-nss-ipv4-reasm=y"    # IPv4 分片重组
	"CONFIG_PACKAGE_kmod-qca-nss-ipv6-reasm=y"    # IPv6 分片重组
	"CONFIG_PACKAGE_kmod-qca-nss-tun6rd=y"        # 6in4 隧道
	"CONFIG_PACKAGE_kmod-qca-nss-tunipip6=y"      # 6rd 隧道
	"CONFIG_PACKAGE_kmod-qca-nss-gre=y"           # GRE 隧道
	"CONFIG_PACKAGE_kmod-qca-nss-tunipip4=y"      # IPinIP 隧道
	"CONFIG_PACKAGE_kmod-qca-nss-vxlan=y"         # VXLAN 隧道
	"CONFIG_PACKAGE_kmod-qca-nss-mirror=y"        # 端口镜像
	"CONFIG_PACKAGE_kmod-qca-nss-pptp=y"          # PPTP VPN
	"CONFIG_PACKAGE_kmod-qca-nss-l2tp=y"          # L2TP VPN
	"CONFIG_PACKAGE_kmod-qca-nss-qdisc=y"         # QoS 调度
	"CONFIG_PACKAGE_kmod-qca-nss-shaper=y"        # 流量整形
	"CONFIG_PACKAGE_kmod-qca-nss-ifb=y"           # IFB 接口
	"CONFIG_PACKAGE_kmod-qca-nss-netlink=y"       # Netlink 接口

	# ============================================
	# 修复缺失的依赖包
	# ============================================
	"CONFIG_PACKAGE_libparted=y"                  # 分区工具库（fatresize 依赖）
	"CONFIG_PACKAGE_nikki=y"                      # Nikki 工具（luci-app-nikki 依赖）
	"CONFIG_PACKAGE_python3-pysocks=y"            # Python3 Socks 库
	"CONFIG_PACKAGE_python3-unidecode=y"          # Python3 Unicode 解码库
)

DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"

# ============================================
# 14. NOWIFI 版本专属配置
# ============================================
if [[ $FIRMWARE_TAG == *"NOWIFI"* ]]; then
	provided_config_lines+=(
		"CONFIG_PACKAGE_hostapd-common=n"
		"CONFIG_PACKAGE_wpad-openssl=n"
		# USB 3.0 支持
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
		"CONFIG_PACKAGE_kmod-usb-net-rndis=y"
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
	# 打印机支持 CUPS
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
rm ./target/linux/qualcommax/patches-6.12/0083-v6.11-arm64-dts-qcom-ipq6018-add-sdhci-node.patch

# 创建 ipq6018-nowifi.dtsi 文件以修复 NOWIFI 版本编译错误
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

/* 删除 WiFi 相关节点 */
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
# 修复文件
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \;
sed -i '/\/usr\/bin\/zsh/d' package/base-files/files/etc/profile
find ./ -name "cascade.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "dark.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "cascade.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "dark.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;

# ============================================
# 18. UCI 默认值设置
# ============================================
# 修改ttyd为免密
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" "package/base-files/files/etc/uci-defaults/99_ttyd-nopass"
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" "package/base-files/files/etc/uci-defaults/99_set_argon_primary"
# 解决 dropbear 配置的 bug
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" "package/base-files/files/etc/uci-defaults/99_dropbear_setup"
if [[ $FIRMWARE_TAG == *"EMMC"* ]]; then
	# 解决 nginx 的问题
	install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_nginx_setup.sh" "package/base-files/files/etc/uci-defaults/99_nginx_setup"
fi

# ============================================
# 19. Golang 编译器更新
# ============================================
GOLANG_REPO="https://github.com/sbwml/packages_lang_golang"
GOLANG_BRANCH="25.x"
if [[ -d ./feeds/packages/lang/golang ]]; then \
	rm -rf ./feeds/packages/lang/golang
	git clone $GOLANG_REPO -b $GOLANG_BRANCH ./feeds/packages/lang/golang
fi
