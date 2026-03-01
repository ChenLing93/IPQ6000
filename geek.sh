#!/bin/bash

# 修改默认IP
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd


# 移除要替换的包 (保持原样)
# rm -rf feeds/packages/net/mosdns
# ... (其他注释掉的删除操作)

# Git稀疏克隆函数 (保持原样)
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# -------------------------------------------
# 添加额外插件区域
# -------------------------------------------
# 【新增】集客 AC 控制器 (Geek AC)
echo "正在下载 集客AC 控制器 ..."
# 来源：kenzok8/openwrt-packages (这是一个常用的整合源，包含 gecoos-ac)
git_sparse_clone master https://github.com/kenzok8/openwrt-packages luci-app-gecoos-ac

# 原有插件: Nikki
git_sparse_clone main https://github.com/nikkinikki-org/OpenWrt-nikki nikki
git_sparse_clone main https://github.com/nikkinikki-org/OpenWrt-nikki luci-app-nikki

# 【新增】iStore 应用商店
echo "正在下载 iStore ..."
git_sparse_clone main https://github.com/linkease/istore istore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui

# 原有插件: Onliner
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh

# -------------------------------------------
# Feed 更新与安装
# -------------------------------------------

# 更新并安装所有 feeds (包括刚才克隆的和本地的)
./scripts/feeds update -a
./scripts/feeds install -a

# 【新增】显式安装 CUPS 相关包 (确保从 feeds 链接到 package 目录)
echo "正在配置 CUPS 打印服务..."
./scripts/feeds install luci-app-cups cups cups-filters

# 如果有 USB 打印机需求，建议也启用内核模块 (可选，需确认 .config 中是否开启)
# ./scripts/feeds install kmod-usb-printer

# -------------------------------------------
# 其他系统修改
# -------------------------------------------

# SmartDNS (保持注释，使用 .config 中的配置)
# git clone ...

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings

# 最终再次更新确保万无一失
./scripts/feeds update -a
./scripts/feeds install -a


install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_ttyd-nopass.sh" "package/base-files/files/etc/uci-defaults/99_ttyd-nopass"
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_set_argon_primary.sh" "package/base-files/files/etc/uci-defaults/99_set_argon_primary"
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99-distfeeds.conf" "package/emortal/default-settings/files/99-distfeeds.conf"
sed -i "/define Package\/default-settings\/install/a\\ \\t\$(INSTALL_DIR) \$(1)/etc\\n\ \t\$(INSTALL_DATA) ./files/99-distfeeds.conf \$(1)/etc/99-distfeeds.conf\n" "package/emortal/default-settings/Makefile"
sed -i "/exit 0/i\\ [ -f \'/etc/99-distfeeds.conf\' ] && mv \'/etc/99-distfeeds.conf\' \'/etc/opkg/distfeeds.conf\'\n\ sed -ri \'/check_signature/s@^[^#]@#&@\' /etc/opkg.conf\n" "package/emortal/default-settings/files/99-default-settings"

# 解决 dropbear 配置的 bug
install -Dm755 "${GITHUB_WORKSPACE}/scripts/99_dropbear_setup.sh" "package/base-files/files/etc/uci-defaults/99_dropbear_setup"
