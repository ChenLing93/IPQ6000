#!/bin/bash

# 修改默认IP
sed -i 's/192.168.5.1/10.0.0.1/g' package/base-files/files/bin/config_generate

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
#UPDATE_PACKAGE "luci-app-homeproxy" "immortalwrt/homeproxy" "master"
UPDATE_PACKAGE "luci-app-ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "luci-app-openlist2" "sbwml/luci-app-openlist2" "main"

#small-package
UPDATE_PACKAGE "xray-core xray-plugin dns2tcp dns2socks haproxy hysteria \
naiveproxy shadowsocks-rust v2ray-core v2ray-geodata v2ray-geoview v2ray-plugin \
tuic-client chinadns-ng ipt2socks tcping trojan-plus simple-obfs shadowsocksr-libev \
luci-app-passwall smartdns luci-app-smartdns v2dat mosdns luci-app-mosdns \
taskd luci-lib-xterm luci-lib-taskd luci-app-ssr-plus luci-app-passwall2 \
luci-app-store quickstart luci-app-quickstart luci-app-istorex luci-app-cloudflarespeedtest \
luci-theme-argon netdata luci-app-netdata lucky luci-app-lucky luci-app-openclash mihomo \
luci-app-nikki luci-app-vlmcsd vlmcsd" "kenzok8/small-package" "main" "pkg"

#speedtest
UPDATE_PACKAGE "luci-app-netspeedtest" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"
UPDATE_PACKAGE "speedtest-cli" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"
UPDATE_PACKAGE "luci-app-adguardhome" "https://github.com/ysuolmai/luci-app-adguardhome.git" "master"
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"
UPDATE_PACKAGE "openwrt-podman" "https://github.com/breeze303/openwrt-podman" "main"
UPDATE_PACKAGE "luci-app-quickfile" "https://github.com/sbwml/luci-app-quickfile" "main"

sed -i 's|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-$(ARCH_PACKAGES) $(1)/usr/bin/quickfile|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-aarch64_generic $(1)/usr/bin/quickfile|' package/luci-app-quickfile/quickfile/Makefile

rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname luci-app-diskman -prune)
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname parted -prune)
mkdir -p package/luci-app-diskman && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -O package/luci-app-diskman/Makefile
sed -i 's/fs-ntfs /fs-ntfs3 /g' package/luci-app-diskman/Makefile
sed -i '/ntfs-3g-utils /d' package/luci-app-diskman/Makefile

mkdir -p package/parted && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O package/parted/Makefile

UPDATE_PACKAGE "frp" "https://github.com/ysuolmai/openwrt-frp.git" "main"

keywords_to_delete=(
    "xiaomi_ax3600" "xiaomi_ax9000" "xiaomi_ax1800" "glinet" "jdcloud_ax6600" "mr7350" "uugamebooster" "luci-app-wol" "luci-i18n-wol-zh-cn" "CONFIG_TARGET_INITRAMFS" "ddns" "LSUSB" "mihomo" "smartdns" "kucat" "bootstrap" "homeproxy"
)
[[ $FIRMWARE_TAG == *"NOWIFI"* ]] && keywords_to_delete+=("usb" "wpad" "hostapd")
[[ $FIRMWARE_TAG != *"EMMC"* ]] && keywords_to_delete+=("samba" "autosamba" "disk")
[[ $FIRMWARE_TAG == *"EMMC"* ]] && keywords_to_delete+=("cmiot_ax18" "qihoo_v6" "redmi_ax5=y" "zn_m2")

for keyword in "${keywords_to_delete[@]}"; do
    sed -i "/$keyword/d" ./.config
done

# Configuration lines to append to .config
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
    # CONFIG_PACKAGE_luci-app-homeproxy=y  # ✅ 已取消 luci-app-homeproxy
    # CONFIG_PACKAGE_luci-i18n-homeproxy-zh-cn=y  # ✅ 已取消 luci-app-homeproxy i18n
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
)

DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"

if [[ $FIRMWARE_TAG == *"NOWIFI"* ]]; then
    provided_config_lines+=(
        "CONFIG_PACKAGE_hostapd-common=n"
        "CONFIG_PACKAGE_wpad-openssl=n"
    )
    find "$DTS_PATH" -type f ! -iname '*nowifi*' -exec sed -i \
        -e '/#include "ipq6018.dtsi"/a #include "ipq6018-nowifi.dtsi"' \
        -e '/#include "ipq8074.dtsi"/a #include "ipq8074-nowifi.dtsi"' {} +
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

if [[ "$FIRMWARE_TAG" != *"EMMC"* && "$FIRMWARE_TAG" == *"NOWIFI"* && "$FIRMWARE_TAG" != *"IPQ807X"* ]]; then
    sed -i 's/\s*kmod-[^ ]*usb[^ ]*\s*\\\?//g' ./target/linux/qualcommax/Makefile
    sed -i 's/\s*kmod-[^ ]*ath11k[^ ]*\s*\\\?//g' ./target/linux/qualcommax/Makefile
    echo "已删除 Makefile 中的 USB 相关 package"
fi

rm package/kernel/mac80211/patches/nss/ath11k/999-902-ath11k-fix-WDS-by-disabling-nwds.patch
rm package/kernel/mac80211/patches/nss/subsys/{999-775-wifi-mac80211-Changes-for-WDS-MLD.patch,999-922-mac80211-fix-null-chanctx-warning-for-NSS-dynamic-VLAN.patch}

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

# Append configuration lines to .config
for line in "${provided_config_lines[@]}"; do
    echo "$line" >> .config
done

rm ./target/linux/qualcommax/patches-6.12/0083-v6.11-arm64-dts-qcom-ipq6018-add-sdhci-node.patch

#修复文件
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \;
sed -i '/\/usr\/bin\/zsh/d' package/base-files/files/etc/profile

find ./ -name "cascade.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "dark.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "cascade.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
find ./ -name "dark.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;

#修改ttyd为免密
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" "package/base-files/files/etc/uci-defaults/99_ttyd-nopass"
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" "package/base-files/files/etc/uci-defaults/99_set_argon_primary"
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99-distfeeds.conf" "package/emortal/default-settings/files/99-distfeeds.conf"

sed -i "/define Package\/default-settings\/install/a\\\\ \\\\t\$(INSTALL_DIR) \$(1)/etc\\\\n\\ \\t\$(INSTALL_DATA) ./files/99-distfeeds.conf \$(1)/etc/99-distfeeds.conf\\n" "package/emortal/default-settings/Makefile"

sed -i "/exit 0/i\\\\ [ -f \\'/etc/99-distfeeds.conf\\' ] && mv \\'/etc/99-distfeeds.conf\\' \\'/etc/opkg/distfeeds.conf\\'\\n\\ sed -ri \\'/check_signature/s@^[^#]@#&@\\' /etc/opkg.conf\\n" "package/emortal/default-settings/files/99-default-settings"

#解决 dropbear 配置的 bug
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" "package/base-files/files/etc/uci-defaults/99_dropbear_setup"

if [[ $FIRMWARE_TAG == *"EMMC"* ]]; then
    #解决 nginx 的问题
    install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_nginx_setup.sh" "package/base-files/files/etc/uci-defaults/99_nginx_setup"
fi

# === 修复 mbedtls 编译错误 ===
echo "=== 修复 mbedtls 编译错误 ==="

if [ -f package/libs/mbedtls/Makefile ]; then
    echo "修复 mbedtls Makefile"
    
    # 检查是否已经添加过修复选项
    if ! grep -q "fno-inline-functions" package/libs/mbedtls/Makefile; then
        # 备份
        cp package/libs/mbedtls/Makefile package/libs/mbedtls/Makefile.bak
        
        # 在 TARGET_CFLAGS 行之前添加编译选项
        sed -i '/TARGET_CFLAGS/i\  TARGET_CFLAGS += -fno-inline-functions' package/libs/mbedtls/Makefile
        
        echo "✅ mbedtls Makefile 已修复"
    else
        echo "✅ mbedtls Makefile 已包含修复选项"
    fi
fi

# === 批量检查和修复 Makefile 格式错误（安全版本）===
echo "=== 批量检查和修复 Makefile 格式 ==="

fixed_count=0
checked_count=0
skipped_count=0

# 需要跳过的 Makefile（避免破坏核心包）
skip_patterns=(
    "package/libs/toolchain"
    "package/kernel/linux"
    "package/devel/gcc"
)

find package -name "Makefile" -type f 2>/dev/null | while read makefile; do
    checked_count=$((checked_count + 1))
    
    # 检查是否在跳过列表中
    should_skip=0
    for pattern in "${skip_patterns[@]}"; do
        if [[ "$makefile" == */$pattern/* ]]; then
            should_skip=1
            break
        fi
    done
    
    if [ $should_skip -eq 1 ]; then
        skipped_count=$((skipped_count + 1))
        continue
    fi
    
    # 检查文件是否可读
    if [ ! -r "$makefile" ]; then
        continue
    fi
    
    # 检查是否有行首空格
    if grep -q "^    " "$makefile" 2>/dev/null; then
        echo "[$checked_count] 发现问题: $makefile"
        
        # 备份原文件
        cp "$makefile" "$makefile.bak"
        
        # 修复：将行首 4 个空格替换为 Tab
        sed -i 's/^    /\t/' "$makefile"
        
        # 如果还有空格，尝试更广泛的替换
        if grep -q "^    " "$makefile"; then
            sed -i 's/^[[:space:]]\+/\t/' "$makefile"
        fi
        
        # 验证修复
        if ! grep -q "^    " "$makefile" 2>/dev/null; then
            echo "  ✅ 已修复"
            fixed_count=$((fixed_count + 1))
            rm "$makefile.bak"
        else
            echo "  ⚠️ 修复失败，保留备份"
            mv "$makefile.bak" "$makefile"
        fi
    fi
done

echo "=== Makefile 格式检查完成 ==="
echo "已检查: $checked_count 个文件"
echo "已跳过: $skipped_count 个核心文件"
echo "已修复: $fixed_count 个文件"

# === 设置 Go 环境变量 ===
echo "=== 设置 Go 环境变量 ==="
export GOTOOLCHAIN=auto
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

echo "GOTOOLCHAIN=$GOTOOLCHAIN"
echo "GOPROXY=$GOPROXY"

echo "=== DIY 脚本执行完成 ==="
