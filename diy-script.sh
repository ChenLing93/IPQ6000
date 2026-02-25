#!/bin/bash

# 修改默认IP (如果需要，取消下面注释)
# sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 安装和更新软件包
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

	# 根据 PKG_SPECIAL 处理包
	case "$PKG_SPECIAL" in
		"pkg")
			for NAME in "${PKG_NAMES[@]}"; do
				echo "moving $NAME"
				cp -rf $(find ./package/$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$NAME*" -prune) ./package/ 2>/dev/null
			done
			rm -rf ./package/$REPO_NAME/
			;;
		"name")
			mv -f ./package/$REPO_NAME ./package/$PKG_NAME
			;;
	esac
}

# --- 基础插件安装 ---
UPDATE_PACKAGE "luci-app-poweroff" "esirplayground/luci-app-poweroff" "master"
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"
UPDATE_PACKAGE "openwrt-gecoosac" "lwb1978/openwrt-gecoosac" "main"
UPDATE_PACKAGE "luci-app-ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "luci-app-openlist2" "sbwml/luci-app-openlist2" "main"

# small-package (包含大量常用插件)
# [重要] 已移除 trojan-plus, luci-app-ssr-plus, luci-app-nikki, fatresize 以避免依赖报错导致编译失败
# 功能替代：使用 OpenClash (mihomo) 和 HomeProxy 代理；使用命令行 parted 分区
UPDATE_PACKAGE "xray-core xray-plugin dns2tcp dns2socks haproxy hysteria \
        naiveproxy v2ray-core v2ray-geodata v2ray-geoview v2ray-plugin \
        tuic-client chinadns-ng ipt2socks tcping simple-obfs shadowsocksr-libev \
        luci-app-passwall smartdns luci-app-smartdns v2dat mosdns luci-app-mosbnb \
        taskd luci-lib-xterm luci-lib-taskd luci-app-passwall2 \
        luci-app-store quickstart luci-app-quickstart luci-app-istorex luci-app-cloudflarespeedtest \
        luci-theme-argon netdata luci-app-netdata lucky luci-app-lucky luci-app-openclash mihomo \
        luci-app-vlmcsd vlmcsd" "kenzok8/small-package" "main" "pkg"

# speedtest
UPDATE_PACKAGE "luci-app-netspeedtest" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"
UPDATE_PACKAGE "speedtest-cli" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"

UPDATE_PACKAGE "luci-app-adguardhome" "https://github.com/ysuolmai/luci-app-adguardhome.git" "master"

UPDATE_PACKAGE "luci-app-quickfile" "https://github.com/sbwml/luci-app-quickfile" "main"

# --- [新增] 安装 DDNSTO 支持 ---
echo "📦 Installing DDNSTO packages..."
if ! git clone --depth=1 https://github.com/linkease/nas-packages-luci.git package/nas-packages-luci 2>/dev/null; then
    echo "⚠️ Failed to clone nas-packages-luci, skipping DDNSTO Luci."
fi
if ! git clone --depth=1 https://github.com/linkease/nas-packages.git package/nas-packages 2>/dev/null; then
    echo "⚠️ Failed to clone nas-packages, skipping DDNSTO Core."
fi

if [ -d package/nas-packages-luci/luci/luci-app-ddns-to ]; then
    mv -f package/nas-packages-luci/luci/luci-app-ddns-to package/
fi
if [ -d package/nas-packages/network/services/ddns-to ]; then
    mv -f package/nas-packages/network/services/ddns-to package/
fi
rm -rf package/nas-packages-luci package/nas-packages
echo "✅ DDNSTO installation complete."
# -----------------------------

# 处理 Diskman (手动下载 Makefile)
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname luci-app-diskman -prune) 2>/dev/null
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname parted -prune) 2>/dev/null

mkdir -p package/luci-app-diskman && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -O package/luci-app-diskman/Makefile 2>/dev/null
sed -i 's/fs-ntfs /fs-ntfs3 /g' package/luci-app-diskman/Makefile
sed -i '/ntfs-3g-utils /d' package/luci-app-diskman/Makefile

mkdir -p package/parted && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O package/parted/Makefile 2>/dev/null

UPDATE_PACKAGE "frp" "https://github.com/ysuolmai/openwrt-frp.git" "master"

# --- 设备树与配置裁剪逻辑 ---
# 只保留指定的 qualcommax_ipq60xx 设备
if [[ $FIRMWARE_TAG == *"EMMC"* ]]; then
    keep_pattern="\(redmi_ax5-jdcloud\|jdcloud_re-ss-01\|jdcloud_re-cs-07\)=y$"
else
    keep_pattern="\(redmi_ax5\|qihoo_360v6\|redmi_ax5-jdcloud\|zn_m2\|jdcloud_re-ss-01\|jdcloud_re-cs-07\)=y$"
fi

sed -i "/^CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_/{
    /$keep_pattern/!d
}" ./.config

keywords_to_delete=(
    "uugamebooster" "luci-app-wol" "luci-i18n-wol-zh-cn" "CONFIG_TARGET_INITRAMFS" "ddns" "LSUSB" "mihomo"
    "smartdns" "kucat" "bootstrap"
)

[[ $FIRMWARE_TAG == *"NOWIFI"* ]] && keywords_to_delete+=("usb" "wpad" "hostapd")
[[ $FIRMWARE_TAG != *"EMMC"* ]] && keywords_to_delete+=("samba" "autosamba" "disk")

for keyword in "${keywords_to_delete[@]}"; do
    sed -i "/$keyword/d" ./.config
done

# --- 配置生成 ---
DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
provided_config_lines=()

# 基础通用配置
provided_config_lines+=(
    "CONFIG_PACKAGE_luci-app-zerotier=y"
    "CONFIG_PACKAGE_luci-i18n-zerotier-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-adguardhome=y"
    "CONFIG_PACKAGE_luci-i18n-adguardhome-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-poweroff=y"
    "CONFIG_PACKAGE_luci-i18n-poweroff-zh-cn=y"
    "CONFIG_PACKAGE_cpufreq=y"
    "CONFIG_PACKAGE_luci-app-cpufreq=y"
    "CONFIG_PACKAGE_luci-i18n-cpufreq-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-ttyd=y"
    "CONFIG_PACKAGE_luci-i18n-ttyd-zh-cn=y"
    "CONFIG_PACKAGE_ttyd=y"
    "CONFIG_PACKAGE_luci-app-homeproxy=y"
    "CONFIG_PACKAGE_luci-i18n-homeproxy-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-ddns-go=y"
    "CONFIG_PACKAGE_luci-i18n-ddns-go-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-argon-config=y"
    "CONFIG_PACKAGE_nano=y"
    "CONFIG_BUSYBOX_CONFIG_LSUSB=n"
    "CONFIG_PACKAGE_luci-app-netspeedtest=y"
    "CONFIG_PACKAGE_luci-app-vlmcsd=y"
    "CONFIG_COREMARK_OPTIMIZE_O3=y"
    "CONFIG_COREMARK_ENABLE_MULTITHREADING=y"
    "CONFIG_COREMARK_NUMBER_OF_THREADS=6"
    "CONFIG_PACKAGE_luci-app-filetransfer=y"
    "CONFIG_PACKAGE_openssh-sftp-server=y"
    "CONFIG_PACKAGE_luci-app-frpc=y" 
    "CONFIG_OPKG_USE_CURL=y"
    "CONFIG_PACKAGE_opkg=y"   
    "CONFIG_USE_APK=n"
    "CONFIG_PACKAGE_luci-app-tailscale=y"
    "CONFIG_PACKAGE_luci-app-gecoosac=y"
    "CONFIG_PACKAGE_luci-app-wireguard=y"
    "CONFIG_PACKAGE_wireguard-tools=y"
    "CONFIG_PACKAGE_kmod-wireguard=y"
    
    # [新增] IStore 商店强制开启
    "CONFIG_PACKAGE_luci-app-istorex=y"
    "CONFIG_PACKAGE_luci-i18n-istorex-zh-cn=y"
    "CONFIG_PACKAGE_istore=y"
    
    # [新增] DDNSTO 配置
    "CONFIG_PACKAGE_luci-app-ddns-to=y"
    "CONFIG_PACKAGE_ddns-to=y"
    
    # [新增] USB 打印机支持
    "CONFIG_PACKAGE_kmod-usb-printer=y"
    "CONFIG_PACKAGE_p910nd=y"
    "CONFIG_PACKAGE_luci-app-p910nd=y"

    # --- [关键修复] 硬盘挂载相关依赖 (确保无警告) ---
    
    # 1. Diskman 及分区工具依赖
    "CONFIG_PACKAGE_libparted=y"
    "CONFIG_PACKAGE_parted=y"
    "CONFIG_PACKAGE_e2fsprogs=y"
    "CONFIG_PACKAGE_tune2fs=y"
    
    # 2. 自动挂载核心 (block-mount)
    "CONFIG_PACKAGE_block-mount=y"
    "CONFIG_PACKAGE_blkid=y"
    "CONFIG_PACKAGE_swap-utils=y"
    "CONFIG_PACKAGE_fstools=y"
    "CONFIG_PACKAGE_blockd=y"

    # 3. 文件系统支持 (全格式)
    "CONFIG_PACKAGE_fs-ext4=y"
    "CONFIG_PACKAGE_fs-f2fs=y"
    "CONFIG_PACKAGE_fs-ntfs3=y"
    "CONFIG_PACKAGE_kmod-fs-ntfs3=y"
    "CONFIG_PACKAGE_kmod-fs-exfat=y"
    "CONFIG_PACKAGE_exfat-mkfs=y"
    "CONFIG_PACKAGE_exfat-check=y"
    
    # 4. 网络共享 (可选，方便访问硬盘)
    "CONFIG_PACKAGE_luci-app-samba4=y"
    "CONFIG_PACKAGE_samba4-server=y"

    # --- 依赖修复结束 ---
)

if [[ $FIRMWARE_TAG == *"NOWIFI"* ]]; then
    # --- NOWIFI 特定配置 (包含完整的 USB 支持) ---
    provided_config_lines+=(
        "CONFIG_PACKAGE_hostapd-common=n"
        "CONFIG_PACKAGE_wpad-openssl=n"
        
        # [重要] NOWIFI 版本显式加入 USB 2.0/3.0 及存储、网络支持
        "CONFIG_PACKAGE_kmod-usb-core=y"
        "CONFIG_PACKAGE_kmod-usb2=y"
        "CONFIG_PACKAGE_kmod-usb3=y"
        "CONFIG_PACKAGE_kmod-usb-storage=y"
        "CONFIG_PACKAGE_kmod-usb-storage-extras=y"
        "CONFIG_PACKAGE_kmod-usb-storage-uas=y"
        "CONFIG_PACKAGE_kmod-usb-storage-asmedia=y" # 增加 ASM 主控支持
        
        # USB 网络共享
        "CONFIG_PACKAGE_kmod-usb-net=y"
        "CONFIG_PACKAGE_kmod-usb-net-rndis=y"
        "CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y"
        "CONFIG_PACKAGE_kmod-usb-net-asix-ax88179=y"
        "CONFIG_PACKAGE_kmod-usb-net-rtl8152=y"
        "CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm=y"
        "CONFIG_PACKAGE_kmod-usb-acm=y"
        "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y"
        "CONFIG_PACKAGE_usbutils=y"
    )

    echo "[NOWIFI] preparing nowifi dtsi files..."
    for dtsi in ipq6018-nowifi.dtsi ipq8074-nowifi.dtsi; do
        if [[ -f "${GITHUB_WORKSPACE}/scripts/$dtsi" ]]; then
            if [[ ! -f "$DTS_PATH/$dtsi" ]]; then
                cp "${GITHUB_WORKSPACE}/scripts/$dtsi" "$DTS_PATH/"
                echo "[NOWIFI] copied $dtsi to $DTS_PATH"
            else
                echo "[NOWIFI] $dtsi already exists in $DTS_PATH"
            fi
        else
            echo "[NOWIFI][ERROR] scripts/$dtsi not found!"
            exit 1
        fi
    done

    find "$DTS_PATH" -type f ! -iname '*nowifi*' -exec sed -i \
      -e '/#include "ipq6018.dtsi"/a #include "ipq6018-nowifi.dtsi"' \
      -e '/#include "ipq8074.dtsi"/a #include "ipq8074-nowifi.dtsi"' {} +

    echo "qualcommax set up nowifi successfully!"

else
    # --- 普通版 (带 WIFI) 的 USB 配置 ---
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
        "CONFIG_PACKAGE_kmod-usb3=y"
    )
fi

# EMMC 特定配置
[[ $FIRMWARE_TAG == *"EMMC"* ]] && provided_config_lines+=(
    "CONFIG_PACKAGE_luci-app-docker=m"
    "CONFIG_PACKAGE_luci-i18n-docker-zh-cn=m"
    "CONFIG_PACKAGE_luci-app-dockerman=m"
    "CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn=m"
    "CONFIG_PACKAGE_luci-app-openlist2=y"
    "CONFIG_PACKAGE_luci-i18n-openlist2-zh-cn=y"
    "CONFIG_PACKAGE_iptables-mod-extra=y"
    "CONFIG_PACKAGE_ip6tables-nft=y"
    "CONFIG_PACKAGE_ip6tables-mod-fullconenat=y"
    "CONFIG_PACKAGE_iptables-mod-fullconenat=y"
    "CONFIG_PACKAGE_libip4tc=y"
    "CONFIG_PACKAGE_libip6tc=y"
    "CONFIG_PACKAGE_luci-app-passwall=y"
    "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=n"
    "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=n"
    "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=n"
    "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=n"
    "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=n"
    "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=n"
    "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=n"
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
    "CONFIG_PACKAGE_luci-app-openclash=y"
)

[[ $FIRMWARE_TAG == "IPQ"* ]] && provided_config_lines+=("CONFIG_PACKAGE_sqm-scripts-nss=y")

# 追加配置到 .config
for line in "${provided_config_lines[@]}"; do
    echo "$line" >> .config
done

# --- 补丁与修复 ---
rm -f ./target/linux/qualcommax/patches-6.12/0083-v6.11-arm64-dts-qcom-ipq6018-add-sdhci-node.patch

# 修复 getifaddr.c
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \;
sed -i '/\/usr\/bin\/zsh/d' package/base-files/files/etc/profile

# 修改主题颜色
find ./ -name "cascade.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "dark.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "cascade.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "dark.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;

# 安装自定义脚本 (确保你的仓库 scripts 目录有这些文件)
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" "package/base-files/files/etc/uci-defaults/99_ttyd-nopass" 2>/dev/null || echo "⚠️ 99_ttyd-nopass.sh not found"
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" "package/base-files/files/etc/uci-defaults/99_set_argon_primary" 2>/dev/null || echo "⚠️ 99_set_argon_primary.sh not found"
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99-distfeeds.conf" "package/emortal/default-settings/files/99-distfeeds.conf" 2>/dev/null || echo "⚠️ 99-distfeeds.conf not found"

if [ -f "package/emortal/default-settings/files/99-distfeeds.conf" ]; then
    sed -i "/define Package\/default-settings\/install/a\\
\\t\$(INSTALL_DIR) \$(1)/etc\\n\
\t\$(INSTALL_DATA) ./files/99-distfeeds.conf \$(1)/etc/99-distfeeds.conf\n" "package/emortal/default-settings/Makefile"
fi

sed -i "/exit 0/i\\
[ -f \'/etc/99-distfeeds.conf\' ] && mv \'/etc/99-distfeeds.conf\' \'/etc/opkg/distfeeds.conf\'\n\
sed -ri \'/check_signature/s@^[^#]@#&@\' /etc/opkg.conf\n" "package/emortal/default-settings/files/99-default-settings" 2>/dev/null

install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" "package/base-files/files/etc/uci-defaults/99_dropbear_setup" 2>/dev/null || echo "⚠️ 99_dropbear_setup.sh not found"

# CMAKE 修复
if ! grep -q "CMAKE_POLICY_VERSION_MINIMUM" include/cmake.mk; then
  echo 'CMAKE_OPTIONS += -DCMAKE_POLICY_VERSION_MINIMUM=3.5' >> include/cmake.mk
fi

# Rust 修复
RUST_FILE=$(find ./feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ] && [ -f "${GITHUB_WORKSPACE}/scripts/rust-makefile.patch" ]; then
	echo "Patching Rust..."
	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE
	patch $RUST_FILE ${GITHUB_WORKSPACE}/scripts/rust-makefile.patch
	echo "Rust has been fixed!"
fi

# Mbedtls 修复 (跳过强制 FORTIFY 修改，防止 GCC 14 内联错误)
#echo "ℹ️  Skipping manual mbedtls FORTIFY patch to prevent inline assembly errors with GCC 14."

echo "🔧 Applying aggressive patches for mbedtls 3.6.x on GCC 14..."

MBEDTLS_PATH="package/libs/mbedtls"

if [ -d "$MBEDTLS_PATH" ]; then
    # 1. 备份原 Makefile
    cp "$MBEDTLS_PATH/Makefile" "$MBEDTLS_PATH/Makefile.bak"

    # 2. 注入特殊的 CFLAGS 来禁用导致报错的检查和优化冲突
    # 我们需要在 CMAKE_OPTIONS 中添加特定的标志，或者直接在 Makefile 中覆盖 TARGET_CFLAGS
    
    # 方法：在 Makefile 的 "include $(INCLUDE_DIR)/package.mk" 之前插入 PKG_CFLAGS
    # 这些标志专门用于平息 GCC 14 的过度检查
    sed -i '/include \$(INCLUDE_DIR)\/package.mk/i\
PKG_CFLAGS += -Wno-error=incompatible-pointer-types\
PKG_CFLAGS += -Wno-error=implicit-function-declaration\
PKG_CFLAGS += -Wno-unterminated-string-initialization\
PKG_CFLAGS += -fno-inline-functions-called-once\
PKG_CFLAGS += -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0' "$MBEDTLS_PATH/Makefile"

    echo "✅ mbedtls Makefile patched with GCC 14 compatibility flags."
    
    # 3. (可选) 如果源码中有具体的 CMakeLists.txt 也可以尝试修改，但通常 PKG_CFLAGS 足够穿透
fi

# 同时处理 feeds 中的 mbedtls (如果有)
if [ -d "feeds/packages/libs/mbedtls" ]; then
    MBEDTLS_FEEDS="feeds/packages/libs/mbedtls"
    sed -i '/include \$(INCLUDE_DIR)\/package.mk/i\
PKG_CFLAGS += -Wno-error=incompatible-pointer-types\
PKG_CFLAGS += -Wno-unterminated-string-initialization\
PKG_CFLAGS += -fno-inline-functions-called-once\
PKG_CFLAGS += -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0' "$MBEDTLS_FEEDS/Makefile"
    echo "✅ Feeds mbedtls patched."
fi

echo "ℹ️  Proceeding to compile..."

# ============================================
# Golang 编译器更新 (固定到 25.x 分支)
# ============================================
GOLANG_REPO="https://github.com/sbwml/packages_lang_golang"
GOLANG_BRANCH="25.x"
if [[ -d ./feeds/packages/lang/golang ]]; then 
    rm -rf ./feeds/packages/lang/golang
    if git clone "$GOLANG_REPO" -b "$GOLANG_BRANCH" ./feeds/packages/lang/golang 2>/dev/null; then
        echo "✅ Golang updated to branch $GOLANG_BRANCH successfully."
    else
        echo "⚠️ Failed to update Golang, using default version."
    fi
fi
# ============================================
