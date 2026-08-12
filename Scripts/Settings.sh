#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_CI-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
#修改默认WIFI名
sed -i "s/\.ssid=.*/\.ssid=$WRT_WIFI/g" $(find ./package/kernel/mac80211/ ./package/network/config/ -type f -name "mac80211.*")

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
#修改默认时区
sed -i "s/timezone='.*'/timezone='CST-8'/g" $CFG_FILE
sed -i "/timezone='.*'/a\\\t\t\set system.@system[-1].zonename='Asia/Shanghai'" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
#echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#添加turboacc
if echo "$WRT_SOURCE" | grep -qE "immortalwrt/immortalwrt|openwrt/openwrt" || [ "$WRT_TARGET" == "X86" ]; then
         echo "CONFIG_PACKAGE_luci-app-turboacc=y" >> .config
         echo "start apply patch for turboacc!"
         #curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
         echo "apply patch for turboacc finished!"
fi

#添加ax6和3600大分区stock-layout支持
if [[ $WRT_REPO == *"openwrt"* ]] && [[ $WRT_REPO != *"LiBwrt"* ]]; then
         echo "start apply patch to ax6 and ax3600 stock layout!"
         git apply $GITHUB_WORKSPACE/Config/bak/0001-Add-qualcommax-stock-layout-for-xiaomi-ax3600-and-redmi-ax6.patch
         git apply $GITHUB_WORKSPACE/Config/bak/0001-Add-IPQ_MEM_PROFILE-Support.patch
         echo "apply patch to ax6 and ax3600 stock layout finished!"
fi
