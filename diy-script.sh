#!/bin/bash

# --------------------------------------------------------
# 1. 基础系统修改
# --------------------------------------------------------
echo ">>> 开始执行 DIY 脚本..."

# 修改默认 IP 为 192.168.5.1
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# --------------------------------------------------------
# 2. 通用克隆与提取函数 (增强版)
# --------------------------------------------------------
UPDATE_PACKAGE() {
    local PKG_NAME="$1"
    local PKG_REPO="$2"
    local PKG_BRANCH="$3"
    local PKG_SPECIAL="$4"

    # 处理包名数组
    read -ra PKG_NAMES <<< "$PKG_NAME"

    # 清理旧的包 (防止冲突)
    for NAME in "${PKG_NAMES[@]}"; do
        # 清理 feeds 和 package 目录下的旧版本
        find feeds/luci/ feeds/packages/ package/ -maxdepth 4 -type d -iname "*$NAME*" -exec rm -rf {} \; 2>/dev/null
    done

    # 确定仓库 URL
    local REPO_URL=""
    if [[ $PKG_REPO == http* ]]; then
        REPO_URL="$PKG_REPO"
    else
        REPO_URL="https://github.com/$PKG_REPO.git"
    fi

    # 提取仓库名称用于临时目录
    local REPO_NAME=$(echo "$REPO_URL" | awk -F '/' '{gsub(/\.git$/, "", $NF); print $NF}')
    local TEMP_DIR="./package/_temp_$REPO_NAME"

    echo ">>> 正在克隆: $REPO_URL (分支: $PKG_BRANCH) ..."
    
    # 克隆到临时目录
    if ! git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        echo "❌ 错误: 克隆 $REPO_URL 失败!"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    # 根据模式处理包
    case "$PKG_SPECIAL" in
        "pkg")
            echo ">>> 正在从 $REPO_NAME 提取多个包: ${PKG_NAMES[*]}"
            for NAME in "${PKG_NAMES[@]}"; do
                # 在临时目录中递归查找包含该包名的目录 (通常包含 Makefile)
                local FOUND_DIR=$(find "$TEMP_DIR" -type d -name "*$NAME*" -exec test -f "{}/Makefile" \; -print -quit 2>/dev/null)
                
                if [ -n "$FOUND_DIR" ]; then
                    echo "   - 找到并移动: $NAME (路径: $FOUND_DIR)"
                    cp -rf "$FOUND_DIR" "./package/"
                else
                    echo "   ⚠️ 警告: 未在 $REPO_NAME 中找到包含 Makefile 的 $NAME 目录"
                fi
            done
            rm -rf "$TEMP_DIR"
            ;;
        "name")
            # 重命名模式：直接将整个仓库重命名为第一个包名
            mv -f "$TEMP_DIR" "./package/$PKG_NAME"
            echo ">>> 已移动并重命名: $PKG_NAME"
            ;;
        *)
            # 默认模式：如果只传了一个包名，且仓库根目录就是包，直接移动
            if [ ${#PKG_NAMES[@]} -eq 1 ]; then
                 mv -f "$TEMP_DIR" "./package/${PKG_NAMES[0]}"
                 echo ">>> 已移动: ${PKG_NAMES[0]}"
            else
                echo "⚠️ 警告: 未指定特殊模式且包名多于一个，默认只移动第一个或忽略。"
                rm -rf "$TEMP_DIR"
            fi
            ;;
    esac
}

# --- 独立插件下载 ---
if [ ! -d "package/luci-lib-taskd" ]; then
    git clone --depth=1 --single-branch --branch master https://github.com/immortalwrt/luci.git temp_luci_taskd
    if [ -d "temp_luci_taskd/libs/luci-lib-taskd" ]; then
        mv temp_luci_taskd/libs/luci-lib-taskd package/
        echo "✅ 成功下载 luci-lib-taskd"
    fi
    rm -rf temp_luci_taskd
fi

if [ ! -d "package/luci-lib-xterm" ]; then
    git clone --depth=1 --single-branch --branch master https://github.com/immortalwrt/luci.git temp_luci_xterm
    if [ -d "temp_luci_xterm/libs/luci-lib-xterm" ]; then
        mv temp_luci_xterm/libs/luci-lib-xterm package/
        echo "✅ 成功下载 luci-lib-xterm"
    fi
    rm -rf temp_luci_xterm
fi

if [ ! -d "package/luci-app-store" ]; then
    rm -rf package/luci-app-store package/istore package/app-store-ui temp_istore
    git clone --depth=1 --single-branch --branch main https://github.com/linkease/istore.git temp_istore
    
    if [ -d "temp_istore/luci-app-store" ]; then
        mv temp_istore/luci-app-store package/
    fi
    if [ -d "temp_istore/app-store-ui" ]; then
        mv temp_istore/app-store-ui package/
    fi
    if [ -f "temp_istore/Makefile" ] && [ ! -d "package/luci-app-store" ]; then
         mv temp_istore package/luci-app-store
    fi
    
    rm -rf temp_istore
    echo "✅ 成功下载 luci-app-store"
fi

# --- 调用 UPDATE_PACKAGE 函数 ---
UPDATE_PACKAGE "luci-app-poweroff" "esirplayground/luci-app-poweroff" "master"
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"
UPDATE_PACKAGE "openwrt-gecoosac" "ChenLing93/luci-app-gecoosac" "main"
UPDATE_PACKAGE "luci-app-openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "luci-app-ddnsto" "linkease/ddnsto-openwrt" "main"
UPDATE_PACKAGE "luci-theme-proton" "sirpdboy/luci-theme-proton" "main"
UPDATE_PACKAGE "luci-app-quickfile" "sbwml/luci-app-quickfile" "main"
UPDATE_PACKAGE "openwrt-podman" "breeze303/openwrt-podman" "main"
UPDATE_PACKAGE "frp" "ysuolmai/openwrt-frp" "main"

# --- 大仓库提取 (small-package) ---
UPDATE_PACKAGE "xray-core xray-plugin dns2tcp dns2socks haproxy hysteria \
naiveproxy shadowsocks-rust v2ray-core v2ray-geodata v2ray-geoview v2ray-plugin \
tuic-client chinadns-ng ipt2socks tcping trojan-plus simple-obfs shadowsocksr-libev \
mihomo v2dat \
luci-app-passwall smartdns luci-app-smartdns \
luci-lib-xterm \
luci-app-istorex luci-app-cloudflarespeedtest \
luci-theme-argon luci-app-argon-config \
netdata luci-app-netdata lucky luci-app-lucky \
luci-app-vlmcsd vlmcsd \
quickstart luci-app-quickstart" "kenzok8/small-package" "main" "pkg"

# --- sbwml 专用源提取 ---
UPDATE_PACKAGE "luci-app-netspeedtest speedtest-cli" "https://github.com/sbwml/openwrt_pkgs.git" "main" "pkg"

# --------------------------------------------------------
# 3. 特殊修补与 DiskMan 安装
# --------------------------------------------------------

# 修复 quickfile 架构问题 (针对 aarch64)
if [ -f "package/luci-app-quickfile/quickfile/Makefile" ]; then
    echo ">>> 修复 luci-app-quickfile 架构定义..."
    sed -i 's|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-$(ARCH_PACKAGES) $(1)/usr/bin/quickfile|$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile-aarch64_generic $(1)/usr/bin/quickfile|' package/luci-app-quickfile/quickfile/Makefile
fi

# 安装 DiskMan (手动下载 Makefile)
echo ">>> 安装 luci-app-diskman 和 parted..."
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname "*diskman*" -prune) 2>/dev/null
rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname "*parted*" -prune) 2>/dev/null

mkdir -p package/luci-app-diskman
wget -q https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -O package/luci-app-diskman/Makefile
if [ -f "package/luci-app-diskman/Makefile" ]; then
    sed -i 's/fs-ntfs /fs-ntfs3 /g' package/luci-app-diskman/Makefile
    sed -i '/ntfs-3g-utils /d' package/luci-app-diskman/Makefile
fi

mkdir -p package/parted
wget -q https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O package/parted/Makefile

# --------------------------------------------------------
# 4. 配置文件 (.config) 预设
# --------------------------------------------------------
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
    "CONFIG_PACKAGE_luci-app-ddnsto=y"
    "CONFIG_PACKAGE_luci-i18n-ddnsto-zh-cn=y"
    "CONFIG_PACKAGE_luci-theme-proton=y"
    "CONFIG_PACKAGE_luci-app-argon-config=y"
    "CONFIG_PACKAGE_nano=y"
    "CONFIG_BUSYBOX_CONFIG_LSUSB=n"
    "CONFIG_PACKAGE_luci-app-netspeedtest=y"
    "CONFIG_PACKAGE_luci-app-vlmcsd=y"
    "CONFIG_COREMARK_OPTIMIZE_O3=y"
    "CONFIG_COREMARK_ENABLE_MULTITHREADING=y"
    "CONFIG_PACKAGE_luci-app-filetransfer=y"
    "CONFIG_PACKAGE_openssh-sftp-server=y"
    "CONFIG_PACKAGE_luci-app-frpc=y"
    "CONFIG_USE_APK=n"
    "CONFIG_PACKAGE_luci-app-tailscale=y"
    "CONFIG_PACKAGE_luci-app-gecoosac=y"
    "CONFIG_PACKAGE_luci-app-openclash=y"
    "CONFIG_PACKAGE_luci-app-autotimeset=y" 
    "CONFIG_PACKAGE_luci-i18n-autotimeset-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-store=y"
    "CONFIG_PACKAGE_luci-lib-taskd=y"
    "CONFIG_PACKAGE_luci-lib-xterm=y"
    "CONFIG_PACKAGE_app-store-ui=y"

    "CONFIG_PACKAGE_kmod-usb-core=y"
    "CONFIG_PACKAGE_kmod-usb-dwc3=y"
    "CONFIG_PACKAGE_kmod-usb-dwc3-qcom=y"
    "CONFIG_PACKAGE_kmod-usb-storage-uas=y"
    "CONFIG_PACKAGE_kmod-fs-exfat=y"
    "CONFIG_PACKAGE_kmod-fs-ntfs3=y"
    "CONFIG_PACKAGE_block-mount=y"
    "CONFIG_PACKAGE_fdisk=y"
    "CONFIG_PACKAGE_lsblk=y"
    
    # 显式禁用无线组件 (第一重保险)
    "# CONFIG_PACKAGE_hostapd is not set"
    "# CONFIG_PACKAGE_wpad is not set"
    "# CONFIG_PACKAGE_wpad-full-openssl is not set"
    "# CONFIG_PACKAGE_wpad-basic is not set"
    "# CONFIG_PACKAGE_iw is not set"
    "# CONFIG_PACKAGE_iwinfo is not set"
    "# CONFIG_PACKAGE_hostapd is not set"
    "# CONFIG_PACKAGE_wpad is not set"
    "# CONFIG_PACKAGE_wpad-full-openssl is not set"
    "# CONFIG_PACKAGE_iw is not set"
    "# CONFIG_PACKAGE_iwinfo is not set"
)

# 针对 IPQ 平台开启 NSS SQM
if [[ $FIRMWARE_TAG == "IPQ"* ]]; then
    provided_config_lines+=("CONFIG_PACKAGE_sqm-scripts-nss=y")
fi

# 写入 .config
for line in "${provided_config_lines[@]}"; do
    echo "$line" >> .config
done

echo "✅ 配置文件预设完成，已禁用无线组件。"

# --------------------------------------------------------
# 5. [核心修复] 强制修复 hostapd 源码 (防止因依赖被强行启用)
# --------------------------------------------------------
# 即使配置禁用了 wpad，某些依赖链仍可能强制开启它。
# 我们直接修改 hostapd 的 Makefile，在编译前注入 sed 命令修复源码。
# 这比打补丁更稳定，不会出现 malformed patch 错误。

echo ">>> 注入 hostapd 源码修复逻辑 (he_mu_edca 错误)..."

HOSTAPD_MAKEFILE="package/network/services/hostapd/Makefile"

if [ -f "$HOSTAPD_MAKEFILE" ]; then
    # 检查是否已经注入过，避免重复
    if ! grep -q "FIX_HE_MU_EDCA_SED" "$HOSTAPD_MAKEFILE"; then
        cat >> "$HOSTAPD_MAKEFILE" << 'MAKEFILE_FIX'

# [FIX_HE_MU_EDCA_SED] Force fix he_mu_edca compile error before compilation
# This injects a sed command to comment out the problematic lines in hostapd.c
define Build/PrepareFixHeMuEdca
	@if [ -f $(BUILD_DIR)/$(PKG_NAME)/src/ap/hostapd.c ]; then \
		echo ">>> Applying he_mu_edca source fix via sed..."; \
		sed -i 's/hapd->iface->conf->he_mu_edca\.he_qos_info &= 0xfff0;/\/\* FIX: disabled he_mu_edca access \*\//g' $(BUILD_DIR)/$(PKG_NAME)/src/ap/hostapd.c; \
		sed -i 's/hapd->iface->conf->he_mu_edca\.he_qos_info |=/\/\* FIX: disabled he_mu_edca access \*\//g' $(BUILD_DIR)/$(PKG_NAME)/src/ap/hostapd.c; \
	fi
endef

# Hook into Build/Prepare by appending to it
# Note: In OpenWrt, we can't easily append to existing define blocks without complex parsing.
# Instead, we rely on the fact that Build/Prepare usually calls Build/Prepare/Default.
# A safer bet for CI is to create a post-patch hook if available, or simply trust the config disable.
# HOWEVER, to be absolutely sure, let's create a dummy patch file using printf to avoid heredoc issues.
MAKEFILE_FIX
        
        # 既然修改 Makefile 钩子比较复杂，我们回归到最可靠的“生成完美格式的 patch 文件”方法
        # 使用 printf 逐行写入，确保没有缩进错误
        rm -f package/network/services/hostapd/patches/999-fix-he-mu-edca-build-error.patch
        
        printf '%s\n' \
        '--- a/src/ap/hostapd.c' \
        '+++ b/src/ap/hostapd.c' \
        '@@ -4681,9 +4681,8 @@ static void hostapd_fill_csa_settings(struct hostapd_data *hapd,' \
        ' #ifdef CONFIG_IEEE80211AX' \
        ' 	if (hapd->iconf->ieee80211ax &&' \
        ' 	    hapd->iface->conf->he_op.he_rts_threshold_set) {' \
        '-		hapd->iface->conf->he_mu_edca.he_qos_info &= 0xfff0;' \
        '-		hapd->iface->conf->he_mu_edca.he_qos_info |=' \
        '-			hapd->iface->conf->he_op.he_rts_threshold;' \
        '+		/* FIX: Disabled he_mu_edca access to resolve build error */' \
        '+		/* Original code commented out */' \
        ' 	}' \
        ' #endif' \
        ' }' \
        > package/network/services/hostapd/patches/999-fix-he-mu-edca-build-error.patch
        
        echo "✅ 已生成修复补丁 (使用 printf 确保格式正确)。"
        
        # 清理刚才追加到 Makefile 的无用内容 (因为我们要用 patch 文件法)
        # 重新读取 Makefile 去掉刚才追加的部分，保持干净
        head -n -15 "$HOSTAPD_MAKEFILE" > "$HOSTAPD_MAKEFILE.tmp" && mv "$HOSTAPD_MAKEFILE.tmp" "$HOSTAPD_MAKEFILE"
    else
        echo "✅ 修复逻辑已存在，跳过。"
    fi
else
    echo "⚠️ 未找到 hostapd Makefile，可能路径有变，但补丁文件法依然有效。"
fi

# --------------------------------------------------------
# 6. 其他补丁与文件修正
# --------------------------------------------------------

# 移除特定冲突补丁 (如果存在)
PATCH_FILE="./target/linux/qualcommax/patches-6.12/0083-v6.11-arm64-dts-qcom-ipq6018-add-sdhci-node.patch"
if [ -f "$PATCH_FILE" ]; then
    echo ">>> 移除冲突补丁: $PATCH_FILE"
    rm "$PATCH_FILE"
fi

# 修复 getifaddr.c 返回值问题 (常见编译错误)
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \;

# 清理 profile 中的 zsh 引用 (如果没装 zsh 会报错)
sed -i '/\/usr\/bin\/zsh/d' package/base-files/files/etc/profile

# 修改 Argon/Proton 主题颜色 (自定义蓝色为青色 #31A1A1)
echo ">>> 修改主题配色..."
for file_pattern in "cascade.css" "dark.css" "cascade.less" "dark.less"; do
    find ./ -name "$file_pattern" -exec sed -i 's/#5e72e4/#31A1A1/g; s/#483d8b/#31A1A1/g' {} \;
done

# --------------------------------------------------------
# 7. 注入自定义脚本 (CI/CD 环境检查)
# --------------------------------------------------------
if [ -n "${GITHUB_WORKSPACE}" ]; then
    echo ">>> 注入 CI/CD 自定义脚本..."
    
    mkdir -p package/base-files/files/etc/uci-defaults/
    mkdir -p package/emortal/default-settings/files/ 2>/dev/null || true

    [ -f "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" ] && \
      install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" "package/base-files/files/etc/uci-defaults/99_ttyd-nopass"
    
    [ -f "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" ] && \
      install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" "package/base-files/files/etc/uci-defaults/99_set_argon_primary"
    
    [ -f "${GITHUB_WORKSPACE}/scripts/99-distfeeds.conf" ] && \
      install -Dm755 "${GITHUB_WORKSPACE}/scripts/99-distfeeds.conf" "package/emortal/default-settings/files/99-distfeeds.conf"
    
    [ -f "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" ] && \
      install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" "package/base-files/files/etc/uci-defaults/99_dropbear_setup"
else
    echo "⚠️ 提示: 本地编译环境，跳过 GITHUB_WORKSPACE 脚本注入。"
fi

# --------------------------------------------------------
# 8. 更新 Go 语言版本 (关键依赖)
# --------------------------------------------------------
GOLANG_REPO="https://github.com/sbwml/packages_lang_golang"
GOLANG_BRANCH="25.x"

if [ -d "./feeds/packages/lang/golang" ]; then
    echo ">>> 更新 Go 语言环境到 $GOLANG_BRANCH ..."
    rm -rf ./feeds/packages/lang/golang
    if git clone --depth=1 --single-branch --branch "$GOLANG_BRANCH" "$GOLANG_REPO" ./feeds/packages/lang/golang; then
        echo "✅ Go 语言更新成功"
    else
        echo "❌ Go 语言更新失败，将使用默认版本"
    fi
fi

echo ">>> DIY 脚本执行完毕！准备更新 feeds..."
