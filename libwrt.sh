#!/bin/bash

set -euo pipefail

echo "🚀 OpenWrt IPQ6018 DIY 配置脚本 (适配 LiBwrt 源码)"
echo "=========================================="
echo ""

# ============================================
# 1. 环境检查
# ============================================
echo "📋 步骤 1/6: 环境检查..."

# 检查必要的变量
if [[ -z "${FIRMWARE_TAG:-}" ]]; then
    echo "⚠️  警告: FIRMWARE_TAG 环境变量未设置"
    echo "📝 请设置 FIRMWARE_TAG，例如："
    echo "   export FIRMWARE_TAG=IPQ6018-NOWIFI"
    echo "   export FIRMWARE_TAG=IPQ6018-EMMC"
    echo ""
    # 尝试从 GitHub Actions 环境推断
    if [[ -n "${GITHUB_ENV:-}" ]]; then
        echo "🤖 检测到 GitHub Actions 环境，使用默认值"
        export FIRMWARE_TAG="IPQ6018-NOWIFI"
    else
        echo "❌ 错误: FIRMWARE_TAG 环境变量未设置"
        exit 1
    fi
fi

# 检查当前目录是否为 OpenWrt 根目录
if [[ ! -f "rules.mk" || ! -f "Config.in" ]]; then
    echo "❌ 错误: 当前目录不是 OpenWrt 根目录"
    echo "📝 请在 OpenWrt 源码根目录下运行此脚本"
    exit 1
fi

# 检测源码类型（LiBwrt vs 官方 OpenWrt）
if [[ -f "include/version.mk" ]]; then
    VERSION_INFO=$(cat include/version.mk)
    if echo "$VERSION_INFO" | grep -qi "immortalwrt\|libwrt"; then
        echo "✅ 检测到 LiBwrt/ImmortalWrt 源码"
        SOURCE_TYPE="libwrt"
    else
        echo "✅ 检测到官方 OpenWrt 源码"
        SOURCE_TYPE="openwrt"
    fi
else
    echo "⚠️  警告: 无法检测源码类型，假设为 OpenWrt"
    SOURCE_TYPE="openwrt"
fi

echo "   源码类型: $SOURCE_TYPE"
echo "   FIRMWARE_TAG: $FIRMWARE_TAG"
echo ""

# ============================================
# 2. 软件包更新函数定义
# ============================================
echo "📦 步骤 2/6: 定义软件包更新函数..."

UPDATE_PACKAGE() {
    local PKG_NAME=$1
    local PKG_REPO=$2
    local PKG_BRANCH=$3
    local PKG_SPECIAL=$4

    # 清理旧的包 - 删除 feeds 中已存在的同名包
    read -ra PKG_NAMES <<< "$PKG_NAME"
    for NAME in "${PKG_NAMES[@]}"; do
        rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" -prune 2>/dev/null) || true
    done

    # 克隆仓库 - 从 GitHub 获取软件包源码
    if [[ $PKG_REPO == http* ]]; then
        local REPO_NAME=$(echo $PKG_REPO | awk -F '/' '{gsub(/\.git$/, "", $NF); print $NF}')
        git clone --depth=1 --single-branch --branch $PKG_BRANCH "$PKG_REPO" package/$REPO_NAME 2>/dev/null || {
            echo "⚠️  警告: 克隆 $REPO_NAME 失败，跳过"
            return 1
        }
    else
        local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)
        git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" package/$REPO_NAME 2>/dev/null || {
            echo "⚠️  警告: 克隆 $REPO_NAME 失败，跳过"
            return 1
        }
    fi

    # 根据 PKG_SPECIAL 处理包
    case "$PKG_SPECIAL" in
        "pkg")
            # pkg 模式: 从仓库中提取多个子包到 package 根目录
            for NAME in "${PKG_NAMES[@]}"; do
                echo "📦 移动 $NAME..."
                cp -rf $(find ./package/$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$NAME*" -prune 2>/dev/null) ./package/ || true
            done
            rm -rf ./package/$REPO_NAME/
            ;;
        "name")
            # name 模式: 重命名仓库目录为指定包名
            mv -f ./package/$REPO_NAME ./package/$PKG_NAME 2>/dev/null || true
            ;;
    esac
}

echo "✅ 软件包更新函数已定义"
echo ""

# ============================================
# 3. 基础工具安装
# ============================================
echo "🛠️  步骤 3/6: 安装基础工具..."

UPDATE_PACKAGE "luci-app-poweroff" "esirplayground/luci-app-poweroff" "master" || true
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main" || true
UPDATE_PACKAGE "openwrt-gecoosac" "lwb1978/openwrt-gecoosac" "main" || true
UPDATE_PACKAGE "luci-app-openlist2" "sbwml/luci-app-openlist2" "main" || true

echo "✅ 基础工具已安装"
echo ""

# ============================================
# 4. 科学上网工具集
# ============================================
echo "🔐 步骤 4/6: 安装科学上网工具..."

UPDATE_PACKAGE "xray-core xray-plugin dns2tcp dns2socks haproxy hysteria \
naiveproxy shadowsocks-rust v2ray-core v2ray-geodata v2ray-geoview v2ray-plugin \
tuic-client chinadns-ng ipt2socks tcping trojan-plus simple-obfs shadowsocksr-libev \
luci-app-passwall smartdns luci-app-smartdns v2dat mosdns luci-app-mosdns \
taskd luci-lib-xterm luci-lib-taskd luci-app-ssr-plus luci-app-passwall2 \
luci-app-store quickstart luci-app-quickstart luci-app-istorex luci-app-cloudflarespeedtest \
luci-theme-argon netdata luci-app-netdata lucky luci-app-lucky luci-app-openclash mihomo \
luci-app-nikki luci-app-vlmcsd vlmcsd" "kenzok8/small-package" "main" "pkg" || true

echo "✅ 科学上网工具已安装"
echo ""

# ============================================
# 5. 网络测速工具
# ============================================
echo "📊 步骤 5/6: 安装网络测速工具..."

UPDATE_PACKAGE "luci-app-netspeedtest" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg" || true
UPDATE_PACKAGE "speedtest-cli" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg" || true

echo "✅ 网络测速工具已安装"
echo ""

# ============================================
# 6. 容器与文件工具
# ============================================
echo "🐳 步骤 6/6: 安装容器与文件工具..."

UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main" || true
UPDATE_PACKAGE "openwrt-podman" "https://github.com/breeze303/openwrt-podman" "main" || true
UPDATE_PACKAGE "luci-app-quickfile" "https://github.com/sbwml/luci-app-quickfile" "main" || true

# 修复 quickfile 架构问题
if [[ -f "package/luci-app-quickfile/quickfile/Makefile" ]]; then
    sed -i 's|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-$(ARCH_PACKAGES) $(1)/usr/bin/quickfile|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-aarch64_generic $(1)/usr/bin/quickfile|' package/luci-app-quickfile/quickfile/Makefile || true
    echo "✅ quickfile 架构已修复"
fi

echo "✅ 容器与文件工具已安装"
echo ""

# ============================================
# 7. 磁盘管理工具
# ============================================
echo "💾 步骤 7/6: 安装磁盘管理工具..."

rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname luci-app-diskman -prune 2>/dev/null) || true
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname parted -prune 2>/dev/null) || true

mkdir -p package/luci-app-diskman
wget -q https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -O package/luci-app-diskman/Makefile || {
    echo "⚠️  警告: 下载 luci-app-diskman Makefile 失败"
}
sed -i 's/fs-ntfs /fs-ntfs3 /g' package/luci-app-diskman/Makefile 2>/dev/null || true
sed -i '/ntfs-3g-utils /d' package/luci-app-diskman/Makefile 2>/dev/null || true

mkdir -p package/parted
wget -q https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O package/parted/Makefile || {
    echo "⚠️  警告: 下载 parted Makefile 失败"
}

echo "✅ 磁盘管理工具已安装"
echo ""

# ============================================
# 8. 服务工具
# ============================================
echo "🔧 步骤 8/6: 安装服务工具..."

UPDATE_PACKAGE "frp" "https://github.com/ysuolmai/openwrt-frp.git" "master" || true
UPDATE_PACKAGE "ddnsto" "kenzok8/openwrt-packages" "master" "pkg" || true
UPDATE_PACKAGE "cups" "https://github.com/op4packages/openwrt-cups.git" "master" "pkg" || true
UPDATE_PACKAGE "istore" "linkease/istore" "main" || true

echo "✅ 服务工具已安装"
echo ""

# ============================================
# 9. 5G 调制解调器工具
# ============================================
echo "📡 步骤 9/6: 安装 5G 调制解调器工具..."

UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main" "name" || true

echo "✅ 5G 调制解调器工具已安装"
echo ""

# ============================================
# 10. PassWall 代理工具
# ============================================
echo "🚀 步骤 10/6: 安装 PassWall 代理工具..."

UPDATE_PACKAGE "luci-app-passwall" "Openwrt-Passwall/openwrt-passwall" "main" || true
UPDATE_PACKAGE "xray-core v2ray-geodata v2ray-geosite sing-box chinadns-ng dns2socks hysteria ipt2socks naiveproxy shadowsocks-libev shadowsocks-rust shadowsocksr-libev simple-obfs tcping trojan-plus tuic-client v2ray-plugin xray-plugin geoview shadow-tls" "Openwrt-Passwall/openwrt-passwall-packages" "main" "pkg" || true

echo "✅ PassWall 代理工具已安装"
echo ""

# ============================================
# 12. 配置清理 - 删除不需要的软件包
# ============================================
echo "🧹 步骤 12/6: 清理不需要的软件包..."

if [[ -f ".config" ]]; then
    keywords_to_delete=(
        "xiaomi_ax3600" "xiaomi_ax9000" "xiaomi_ax1800" "glinet" "jdcloud_ax6600"
        "mr7350"  "luci-app-wol" "luci-i18n-wol-zh-cn"
        "CONFIG_TARGET_INITRAMFS" "ddns" "mihomo" "kucat" "bootstrap" "vlmcsd" "luci-app-vlmcsd"
    )

    [[ $FIRMWARE_TAG == *"NOWIFI"* ]] && keywords_to_delete+=("wpad" "hostapd")
    [[ $FIRMWARE_TAG != *"EMMC"* ]] && keywords_to_delete+=("samba" "autosamba" "disk")
    [[ $FIRMWARE_TAG == *"EMMC"* ]] && keywords_to_delete+=("cmiot_ax18" "qihoo_v6" "redmi_ax5" "zn_m2")

    for keyword in "${keywords_to_delete[@]}"; do
        sed -i "/$keyword/d" ./.config 2>/dev/null || true
    done

    echo "✅ 配置清理完成"
else
    echo "⚠️  警告: .config 文件不存在，跳过配置清理"
fi

echo ""

# ============================================
# 13. 软件包配置项 (写入 .config)
# ============================================
echo "⚙️  步骤 13/6: 写入软件包配置项..."

provided_config_lines=(
    "CONFIG_PACKAGE_luci-app-zerotier=y"
    "CONFIG_PACKAGE_luci-i18n-zerotier-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-poweroff=y"
    "CONFIG_PACKAGE_luci-i18n-poweroff-zh-cn=y"
    "CONFIG_PACKAGE_cpufreq=y"
    "CONFIG_PACKAGE_luci-app-cpufreq=y"
    "CONFIG_PACKAGE_luci-i18n-cpufreq-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-ttyd=y"
    "CONFIG_PACKAGE_luci-i18n-ttyd-zh-cn=y"
    "CONFIG_PACKAGE_ttyd=y"
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
    "CONFIG_PACKAGE_luci-app-quickstart"
    "CONFIG_PACKAGE_luci-app-istorex=y"
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

# NOWIFI 版本专属配置
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

# EMMC 版本额外配置
if [[ $FIRMWARE_TAG == *"EMMC"* ]]; then
    provided_config_lines+=(
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
fi

if [[ $FIRMWARE_TAG == "IPQ"* ]]; then
    provided_config_lines+=("CONFIG_PACKAGE_sqm-scripts-nss=y")
fi

# 将配置项追加到 .config 文件
if [[ -f ".config" ]]; then
    for line in "${provided_config_lines[@]}"; do
        echo "$line" >> .config
    done
    echo "✅ 软件包配置项已写入"
else
    echo "⚠️  警告: .config 文件不存在，跳过配置项写入"
fi

echo ""

# ============================================
# 14. 内核补丁与设备树修复 (NOWIFI 版本专用)
# ============================================
if [[ $FIRMWARE_TAG == *"NOWIFI"* ]]; then
    echo "🔨 步骤 14/6: 修复 NOWIFI 版本内核补丁..."

    # 创建 IPQ6018 NOWIFI 设备树文件
    DTS_DIR="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
    mkdir -p "$DTS_DIR"

    cat > "$DTS_DIR/ipq6018-nowifi.dtsi" << 'EOF'
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

    echo "✅ NOWIFI 设备树文件已创建"
else
    echo "📝 非NOWIFI版本，跳过内核补丁修复"
fi

echo ""

# ============================================
# 15. 代码修复
# ============================================
echo "🔧 步骤 15/6: 修复代码兼容性问题..."

# 修复 getifaddr.c 兼容性问题
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \; 2>/dev/null || true

# 修复 zsh 配置问题
sed -i '/\/usr\/bin\/zsh/d' package/base-files/files/etc/profile 2>/dev/null || true

# 修复主题颜色（适配 LiBwrt/ImmortalWrt）
find ./ -name "cascade.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null || true
find ./ -name "dark.css" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null || true
find ./ -name "cascade.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null || true
find ./ -name "dark.less" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \; 2>/dev/null || true

echo "✅ 代码修复完成"
echo ""

# ============================================
# 16. UCI 默认值设置 (GitHub Actions 环境专用)
# ============================================
if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    echo "🔧 步骤 16/6: 设置 UCI 默认值 (GitHub Actions 环境)..."

    # 在 GitHub Actions 环境中，UCI 脚本可能在 $GITHUB_WORKSPACE/scripts/ 目录
    if [[ -d "${GITHUB_WORKSPACE}/scripts" ]]; then
        # 修改 ttyd 为免密
        if [[ -f "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" ]]; then
            install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" "package/base-files/files/etc/uci-defaults/99_ttyd-nopass" 2>/dev/null || true
        fi

        # 设置 Argon 主题为主主题
        if [[ -f "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" ]]; then
            install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" "package/base-files/files/etc/uci-defaults/99_set_argon_primary" 2>/dev/null || true
        fi

        # 解决 dropbear 配置的 bug
        if [[ -f "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" ]]; then
            install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" "package/base-files/files/etc/uci-defaults/99_dropbear_setup" 2>/dev/null || true
        fi

        # 解决 nginx 的问题 (EMMC 版本)
        if [[ $FIRMWARE_TAG == *"EMMC"* ]] && [[ -f "${GITHUB_WORKSPACE}/scripts/99_nginx_setup.sh" ]]; then
            install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_nginx_setup.sh" "package/base-files/files/etc/uci-defaults/99_nginx_setup" 2>/dev/null || true
        fi

        echo "✅ UCI 默认值已设置"
    else
        echo "⚠️  警告: 未找到 scripts 目录，跳过 UCI 设置"
    fi
else
    echo "📝 非 GitHub Actions 环境，跳过 UCI 设置"
fi

echo ""

# ============================================
# 17. Golang 编译器更新
# ============================================
echo "🐹 步骤 17/6: 更新 Golang 编译器..."

GOLANG_REPO="https://github.com/sbwml/packages_lang_golang"
GOLANG_BRANCH="25.x"

if [[ -d ./feeds/packages/lang/golang ]]; then
    rm -rf ./feeds/packages/lang/golang
    git clone $GOLANG_REPO -b $GOLANG_BRANCH ./feeds/packages/lang/golang 2>/dev/null || {
        echo "⚠️  警告: 克隆 Golang 编译器失败，跳过"
    }
    echo "✅ Golang 编译器已更新"
else
    echo "⚠️  警告: 未找到 Golang 目录，跳过更新"
fi

echo ""

# ============================================
# 18. 完成提示
# ============================================
echo "=========================================="
echo "✅ DIY 配置完成！"
echo ""
echo "📝 配置摘要："
echo "   源码类型: $SOURCE_TYPE"
echo "   FIRMWARE_TAG: $FIRMWARE_TAG"
echo "   已安装工具: PassWall, OpenClash, Tailscale, Diskman, Podman 等"
echo ""
echo "🚀 下一步操作："
if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    echo "   GitHub Actions 将自动继续执行后续步骤"
else
    echo "   1. 重新生成配置："
    echo "      make defconfig"
    echo ""
    echo "   2. 开始编译固件："
    echo "      make -j\$(nproc) V=s"
fi
echo ""
echo "🔧 如果遇到编译错误，请检查："
echo "   1. 磁盘空间是否充足（建议至少 20GB）"
echo "   2. 网络连接是否正常"
echo "   3. 主机环境依赖是否完整"
echo ""
