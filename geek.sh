#!/bin/bash

# --------------------------------------------------------
# 1. 基础系统修改
# --------------------------------------------------------

echo ">>> 开始执行 DIY 脚本..."

# 修改默认 IP 为 192.168.5.1
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh (按需开启)
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# --------------------------------------------------------
# 2. Git 稀疏克隆函数 (增强版)
# --------------------------------------------------------
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  
  echo "正在克隆: $repourl (分支: $branch) -> 目标: $@"
  
  if ! git clone --depth=1 -b "$branch" --single-branch --filter=blob:none --sparse "$repourl" "$repodir"; then
    echo "错误: 克隆 $repourl 失败!"
    return 1
  fi
  
  cd "$repodir"
  git sparse-checkout set "$@"
  
  for dir in "$@"; do
    if [ -d "$dir" ]; then
      mv -f "$dir" ../package/
      echo "成功移动: $dir"
    else
      echo "警告: 在 $repodir 中未找到目录 $dir"
    fi
  done
  
  cd ..
  rm -rf "$repodir"
}

# --------------------------------------------------------
# 3. 添加额外插件区域
# --------------------------------------------------------

# 【1】集客 AC 控制器 (Geek AC)
echo ">>> 添加 集客AC 控制器 ..."
git_sparse_clone master https://github.com/kenzok8/openwrt-packages luci-app-gecoosac

# 【2】Nikki (科学上网)
echo ">>> 添加 Nikki ..."
git_sparse_clone main https://github.com/nikkinikki-org/OpenWrt-nikki nikki
git_sparse_clone main https://github.com/nikkinikki-org/OpenWrt-nikki luci-app-nikki

# 【3】iStore 应用商店
echo ">>> 添加 iStore ..."
git_sparse_clone main https://github.com/linkease/istore istore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui

# 【4】定时设置 (AutoTimeSet) <--- 已替换 autoreboot
echo ">>> 添加 定时设置插件 (luci-app-autotimeset) ..."
# 来源：ImmortalWrt
# 注意：ImmortalWrt 中该插件位于 applications/luci-app-autotimeset
git_sparse_clone master https://github.com/immortalwrt/luci applications/luci-app-autotimeset

# 【5】Onliner (网速显示)
echo ">>> 添加 Onliner ..."
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner

# 配置 Onliner
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
  sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
fi

if [ -f "package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh" ]; then
  chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh
fi

# --------------------------------------------------------
# 4. Feed 更新与安装
# --------------------------------------------------------

echo ">>> 更新 Feeds 索引..."
./scripts/feeds update -a

echo ">>> 安装 Feeds 包..."
# 显式安装列表，确保包含新加入的 autotimeset
./scripts/feeds install -a
./scripts/feeds install  istore app-store-ui luci-app-cups cups cups-filters luci-i18n-cups-zh-cn luci-app-ddnsto ddnsto luci-app-onliner luci-app-autotimeset kmod-usb-printer

# --------------------------------------------------------
# 5. 其他系统美化与修正
# --------------------------------------------------------

# 修改后台首页时间显示格式
if [ -f "package/lean/autocore/files/*/index.htm" ]; then
  sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm
fi

# 修改固件版本信息显示为编译日期
echo ">>> 修改固件版本号..."
date_version=$(date +"%y.%m.%d")
settings_file="package/lean/default-settings/files/zzz-default-settings"

if [ -f "$settings_file" ]; then
  orig_version=$(grep "DISTRIB_REVISION=" "$settings_file" | awk -F "'" '{print $2}')
  if [ -n "$orig_version" ]; then
    sed -i "s/${orig_version}/R${date_version} by Haiibo/g" "$settings_file"
    echo "版本号已更新为: R${date_version} by Haiibo"
  fi
fi

# --------------------------------------------------------
# 6. 注入自定义脚本 (CI/CD 环境)
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
  echo "提示: 本地编译模式，跳过 CI/CD 脚本注入。"
fi

echo ">>> DIY 脚本执行完毕！"
