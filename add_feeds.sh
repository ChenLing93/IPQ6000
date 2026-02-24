#!/bin/bash
# 检查并添加 small-package 源
if ! grep -q "small-package" "$OPENWRT_PATH/feeds.conf.default"; then
    sed -i '$a src-git small8 https://github.com/kenzok8/small-package' $OPENWRT_PATH/feeds.conf.default
fi
