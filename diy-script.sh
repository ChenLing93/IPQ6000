#!/bin/bash

# ============================================
# 修改默认IP (上游192.168.1.1 → 192.168.5.1)
# ============================================
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/etc/config/network

#安装和更新软件包
UPDATE_PACKAGE() {
    local PKG_NAME=$1
    local PKG_REPO=$2
    local PKG_BRANCH=$3
    local PKG_SPECIAL=$4

    # 清理旧的包
    read -ra PKG_NAMES <<< "$PKG_NAME"
    for NAME in "${PKG_NAMES[@]}"; do
        rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" -prune)
    done

    # 克隆仓库
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
            for NAME in "${PKG_NAMES[@]}"; do
                echo "moving $NAME"
                cp -rf $(find ./package/$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$NAME*" -prune) ./package/
            done
            rm -rf ./package/$REPO_NAME/
            ;;
        "name")
            mv -f ./package/$REPO_NAME ./package/$PKG_NAME
            ;;
    esac
}

UPDATE_PACKAGE "luci-app-poweroff" "esirplayground/luci-app-poweroff" "master"
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"
UPDATE_PACKAGE "openwrt-gecoosac" "lwb1978/openwrt-gecoosac" "main"
# HomeProxy 已删除
UPDATE_PACKAGE "luci-app-ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "luci-app-openlist2" "sbwml/luci-app-openlist2" "main"

# small-package - 已删除 openclash mihomo homeproxy
UPDATE_PACKAGE "xray-core xray-plugin dns2tcp dns2socks haproxy hysteria \
naiveproxy shadowsocks-rust v2ray-core v2ray-geodata v2ray-geoview v2ray-plugin \
tuic-client chinadns-ng ipt2socks tcping trojan-plus simple-obfs shadowsocksr-libev \
luci-app-passwall smartdns luci-app-smartdns v2dat mosdns luci-app-mosbnb \
taskd luci-lib-xterm luci-lib-taskd luci-app-ssr-plus luci-app-passwall2 \
luci-app-store quickstart luci-app-quickstart luci-app-istorex luci-app-cloudflarespeedtest \
luci-theme-argon netdata luci-app-netdata lucky luci-app-lucky luci-app-nikki luci-app-vlmcsd vlmcsd" "kenzok8/small-package" "main" "pkg"

# speedtest
UPDATE_PACKAGE "luci-app-netspeedtest" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"
UPDATE_PACKAGE "speedtest-cli" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"
UPDATE_PACKAGE "luci-app-adguardhome" "https://github.com/ysuolmai/luci-app-adguardhome.git" "master"
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"
UPDATE_PACKAGE "openwrt-podman" "https://github.com/breeze303/openwrt-podman" "main"
UPDATE_PACKAGE "luci-app-quickfile" "https://github.com/sbwml/luci-app-quickfile" "main"

sed -i 's|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-$(ARCH_PACKAGES) $(1)/usr/bin/quickfile|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-aarch64_generic $(1)/usr/bin/quickfile|' package/luci-app-quickfile/quickfile/Makefile

# ============================================
# 添加 iStore 和 DDNSTO
# ============================================
UPDATE_PACKAGE "luci-app-istore" "linkease/istore" "main" "pkg"
UPDATE_PACKAGE "ddnsto luci-app-ddnsto" "linkease/openwrt-packages" "main" "pkg"

# 添加 diskman 和 parted
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname luci-app-diskman -prune)
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname parted -prune)
mkdir -p package/luci-app-diskman && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -O package/luci-app-diskman/Makefile
sed -i 's/fs-ntfs /fs-ntfs3 /g' package/luci-app-diskman/Makefile
sed -i '/ntfs-3g-utils /d' package/luci-app-diskman/Makefile
mkdir -p package/parted && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O package/parted/Makefile

UPDATE_PACKAGE "frp" "https://github.com/ysuolmai/openwrt-frp.git" "master"

# ============================================
# 关键词删除列表 (已移除 ddns，避免影响 ddns-go)
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
    "mihomo"
    "kucat"
    "bootstrap"
    "vlmcsd"
    "luci-app-vlmcsd"
    "openclash"
    "homeproxy"
)

[[ $FIRMWARE_TAG == *"NOWIFI"* ]] && keywords_to_delete+=("wpad" "hostapd")
[[ $FIRMWARE_TAG != *"EMMC"* ]] && keywords_to_delete+=("samba" "autosamba")
[[ $FIRMWARE_TAG == *"EMMC"* ]] && keywords_to_delete+=("cmiot_ax18" "qihoo_v6" "redmi_ax5=y" "zn_m2")

for keyword in "${keywords_to_delete[@]}"; do
    sed -i "/$keyword/d" ./.config
done

# ============================================
# 配置行追加
# ============================================
provided_config_lines=(
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
    # HomeProxy 已删除
    "CONFIG_PACKAGE_luci-app-ddns-go=y"
    "CONFIG_PACKAGE_luci-i18n-ddns-go-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-argon-config=y"
    "CONFIG_PACKAGE_nano=y"
    "CONFIG_BUSYBOX_CONFIG_LSUSB=y"
    "CONFIG_PACKAGE_luci-app-netspeedtest=y"
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
    "CONFIG_PACKAGE_usbutils=y"
    "CONFIG_PACKAGE_luci-app-diskman=y"
    "CONFIG_PACKAGE_luci-i18n-diskman-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-autoreboot=y"
    "CONFIG_PACKAGE_luci-i18n-autoreboot-zh-cn=y"
    # 打印机支持 CUPS
    "CONFIG_PACKAGE_cups=y"
    "CONFIG_PACKAGE_cups-bsd=y"
    "CONFIG_PACKAGE_cups-client=y"
    "CONFIG_PACKAGE_kmod-usb-printer=y"
    # iStore 和 DDNSTO
    "CONFIG_PACKAGE_luci-app-istore=y"
	 "CONFIG_PACKAGE_luci-app-quickstart"
    "CONFIG_PACKAGE_ddnsto=y"
    "CONFIG_PACKAGE_luci-app-ddnsto=y"
    # 运行库
    "CONFIG_PACKAGE_parted=y"
    "CONFIG_PACKAGE_libparted=y"
    "CONFIG_PACKAGE_fatresize=y"
    "CONFIG_PACKAGE_nikki=y"
    "CONFIG_PACKAGE_luci-app-nikki=y"
    "CONFIG_PACKAGE_python3=y"
    "CONFIG_PACKAGE_python3-pysocks=y"
    "CONFIG_PACKAGE_python3-unidecode=y"
    "CONFIG_PACKAGE_python3-light=y"
)

DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"

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
        "CONFIG_PACKAGE_block-mount=y"
        "CONFIG_PACKAGE_kmod-usb-dwc3=y"
        "CONFIG_PACKAGE_kmod-usb-dwc3-qcom=y"
    )

    # 创建 nowifi DTSI 文件
    mkdir -p "$DTS_PATH"
    cat > "$DTS_PATH/ipq6018-nowifi.dtsi" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
#include "ipq6018.dtsi"
/ {
    model = "Qualcomm Technologies, Inc. IPQ6018-512M-NOWIFI";
    compatible = "qcom,ipq6018";
};
&wifi0 { status = "disabled"; };
&wifi1 { status = "disabled"; };
EOF

    # 修改 DTS 引用
    find "$DTS_PATH" -type f -name "*.dts" -exec sed -i \
      -e '/#include "ipq6018.dtsi"/a #include "ipq6018-nowifi.dtsi"' {} +
    echo "qualcommax set up nowifi successfully!"

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
        "CONFIG_PACKAGE_kmod-usb-ohci=y"
        "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y"
        "CONFIG_PACKAGE_kmod-usb-storage=y"
        "CONFIG_PACKAGE_kmod-usb2=y"
    )
fi

# EMMC 版本额外配置
[[ $FIRMWARE_TAG == *"EMMC"* ]] && provided_config_lines+=(
    "CONFIG_PACKAGE_luci-app-podman=y"
    "CONFIG_PACKAGE_podman=y"
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
    "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=n"
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
    # OpenClash 已删除
    "CONFIG_PACKAGE_luci-app-quickfile=y"
)

[[ $FIRMWARE_TAG == "IPQ"* ]] && provided_config_lines+=("CONFIG_PACKAGE_sqm-scripts-nss=y")

# ============================================
# 追加配置到 .config
# ============================================
for line in "${provided_config_lines[@]}"; do
    echo "$line" >> .config
done

# ============================================
# 强制写入易丢失配置 (安全版本)
# ============================================
force_configs=(
    "CONFIG_PACKAGE_libparted=y"
    "CONFIG_PACKAGE_parted=y"
    "CONFIG_PACKAGE_fatresize=y"
    "CONFIG_PACKAGE_nikki=y"
    "CONFIG_PACKAGE_luci-app-nikki=y"
    "CONFIG_PACKAGE_python3=y"
    "CONFIG_PACKAGE_python3-pysocks=y"
    "CONFIG_PACKAGE_python3-unidecode=y"
    "CONFIG_PACKAGE_python3-light=y"
    "CONFIG_PACKAGE_luci-app-istore=y"
    "CONFIG_PACKAGE_ddnsto=y"
    "CONFIG_PACKAGE_luci-app-ddnsto=y"
)

for line in "${force_configs[@]}"; do
    config_key=$(echo "$line" | cut -d '=' -f 1)
    grep -v "^${config_key}=" .config > .config.tmp 2>/dev/null || true
    grep -v "^# ${config_key} " .config >> .config.tmp 2>/dev/null || true
    mv .config.tmp .config
    echo "$line" >> .config
done

# ============================================
# 更新 feeds 并解析依赖 (关键！修复 .config 格式错误)
# ============================================
echo "正在更新 feeds..."
./scripts/feeds update -a > /dev/null 2>&1
echo "正在安装 feeds..."
./scripts/feeds install -a > /dev/null 2>&1
echo "正在解析配置依赖..."
make defconfig > /dev/null 2>&1

# 验证配置
echo "=== 验证关键配置 ==="
grep "CONFIG_PACKAGE_libparted" .config || echo "❌ libparted 未生效"
grep "CONFIG_PACKAGE_nikki" .config || echo "❌ nikki 未生效"
grep "CONFIG_PACKAGE_python3-pysocks" .config || echo "❌ python3-pysocks 未生效"
grep "CONFIG_PACKAGE_luci-app-istore" .config || echo "❌ istore 未生效"
grep "CONFIG_PACKAGE_ddnsto" .config || echo "❌ ddnsto 未生效"
grep "192.168.5.1" package/base-files/files/bin/config_generate && echo "✅ IP 修改成功" || echo "❌ IP 修改失败"

# 删除有问题的补丁
rm -f ./target/linux/qualcommax/patches-6.12/0083-v6.11-arm64-dts-qcom-ipq6018-add-sdhci-node.patch

# 修复文件
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \;
sed -i '/\/usr\/bin\/zsh/d' package/base-files/files/etc/profile

find ./ -name "cascade.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "dark.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "cascade.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "dark.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;

# 修改 ttyd 为免密
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" "package/base-files/files/etc/uci-defaults/99_ttyd-nopass"
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" "package/base-files/files/etc/uci-defaults/99_set_argon_primary"

# 解决 dropbear 配置的 bug
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" "package/base-files/files/etc/uci-defaults/99_dropbear_setup"

if [[ $FIRMWARE_TAG == *"EMMC"* ]]; then
    install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_nginx_setup.sh" "package/base-files/files/etc/uci-defaults/99_nginx_setup"
fi

# update golang
GOLANG_REPO="https://github.com/sbwml/packages_lang_golang"
GOLANG_BRANCH="25.x"
if [[ -d ./feeds/packages/lang/golang ]]; then
    rm -rf ./feeds/packages/lang/golang
    git clone $GOLANG_REPO -b $GOLANG_BRANCH ./feeds/packages/lang/golang
fi
