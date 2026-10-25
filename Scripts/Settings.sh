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
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=n" >> ./.config

#配置ath11k内存
if [[ "$MEM1G" == "true" ]]; then
  echo "CONFIG_ATH11K_MEM_PROFILE_1G=y" >> ./.config
  echo "CONFIG_NSS_MEM_PROFILE_HIGH=y" >> ./.config
  echo "apply ATH11K MEM PROFILE 1G!"
fi

if [[ "$MEM1G" == "false" ]]; then
  echo "CONFIG_ATH11K_MEM_PROFILE_512M=y" >> ./.config
  echo "CONFIG_NSS_MEM_PROFILE_MEDIUM=y" >> ./.config
  echo "apply ATH11K MEM PROFILE 512M!"
fi


#JuliusBairaktaris设置
if [[ $WRT_REPO == *"JuliusBairaktaris"* ]]; then
echo "CONFIG_PACKAGE_kmod-nss-wifi-drv=y" >> ./.config
echo "CONFIG_ATH11K_NSS_WIFI=y" >> ./.config
echo "CONFIG_PACKAGE_nss-firmware=y" >> ./.config
echo "CONFIG_PACKAGE_nss-firmware-ipq807x=y" >> ./.config
echo "CONFIG_PACKAGE_wpad-openssl=y" >> ./.config
echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
echo "CONFIG_PACKAGE_kmod-qca-nss-drv=y" >> ./.config
echo "CONFIG_PACKAGE_kmod-qca-nss-ecm=y" >> ./.config
echo "CONFIG_PACKAGE_kmod-qca-nss-drv-pppoe=y" >> ./.config
echo "CONFIG_PACKAGE_kmod-qca-nss-drv-qdisc=y" >> ./.config
echo "CONFIG_PACKAGE_kmod-qca-nss-drv-igs=y" >> ./.config
echo "CONFIG_PACKAGE_ppe-qos=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-ppe-qos=y" >> ./.config
fi

#添加ax6和3600大分区stock-layout支持
if [[ $WRT_REPO == *"openwrt"* ]]; then
  echo "start apply patch to ax6 and ax3600 stock layout!"
  git apply $GITHUB_WORKSPACE/Scripts/ax3600-ax6-stock-layout.patch
  echo "apply patch to ax6 and ax3600 stock layout finished!"
fi
