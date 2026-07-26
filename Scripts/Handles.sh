#!/bin/bash
set -e

PKG_PATCH="$GITHUB_WORKSPACE/wrt/package/"

cd "$GITHUB_WORKSPACE/wrt/"

# 优先 feeds，其次 package
OPENCLASH_DIR=$(find ./feeds/luci/applications -type d -name "luci-app-openclash" 2>/dev/null | head -n1)
[ -z "$OPENCLASH_DIR" ] && OPENCLASH_DIR=$(find ./package -type d -name "luci-app-openclash" 2>/dev/null | head -n1)

echo "OPENCLASH_DIR=$OPENCLASH_DIR"

[ -n "$OPENCLASH_DIR" ] || { echo "OpenClash not found"; exit 1; }

echo "OPENCLASH_DIR=$OPENCLASH_DIR" >> "$GITHUB_ENV"

cd "$OPENCLASH_DIR"

# 架构判断
if echo "$WRT_TARGET" | grep -Eiq "64|86"; then
    CORE_TYPE="amd64"
elif echo "$WRT_TARGET" | grep -Eiq "IPQ807X"; then
    CORE_TYPE="arm64"
elif echo "$WRT_TARGET" | grep -Eiq "MT7621"; then
    CORE_TYPE="mipsle-softfloat"
else
    CORE_TYPE="$WRT_TARGET"
fi

CORE_MATE="https://github.com/$CLASHSOURCE/raw/core/master/smart/clash-linux-$CORE_TYPE.tar.gz"

cd root/etc/openclash/
mkdir -p core && cd core

curl -fsSL -o meta.tar.gz "$CORE_MATE"
tar -zxf meta.tar.gz
mv -f clash clash_meta
chmod +x ./*
rm -f ./*.gz

echo "openclash core updated"

# GEO 数据
cd ..

curl -fsSL -o Country.mmdb https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country-only-cn-private.mmdb
curl -fsSL -o GeoSite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat
curl -fsSL -o GeoIP.dat https://raw.githubusercontent.com/Loyalsoldier/geoip/release/geoip-only-cn-private.dat

echo "Geo data updated"

if echo "$WRT_TARGET" | grep -Eiq "64|86"; then
    CORE_TYPE="x86_64"
elif echo "$WRT_TARGET" | grep -Eiq "IPQ807X"; then
    CORE_TYPE="arm64"
elif echo "$WRT_TARGET" | grep -Eiq "MT7621"; then
    CORE_TYPE="mips32el"
else
    CORE_TYPE="$WRT_TARGET"
fi

# Fake 工具
curl -fsSL -o FakeHTTP.tar.gz "https://github.com/MikeWang000000/FakeHTTP/releases/latest/download/fakehttp-linux-$CORE_TYPE.tar.gz"
tar -zxf FakeHTTP.tar.gz
mv fakehttp-linux-$CORE_TYPE/fakehttp ./
rm -rf fakehttp-linux-$CORE_TYPE

curl -fsSL -o FakeSIP.tar.gz "https://github.com/MikeWang000000/FakeSIP/releases/latest/download/fakesip-linux-$CORE_TYPE.tar.gz"
tar -zxf FakeSIP.tar.gz
mv fakesip-linux-$CORE_TYPE/fakesip ./
rm -rf fakesip-linux-$CORE_TYPE

chmod +x fakehttp fakesip
rm -f *.gz

# LightGBM
curl -fsSL -o Model.bin https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model.bin

echo "Extra components done"

# 修复OOM
cd "$GITHUB_WORKSPACE/wrt/"
cd "$OPENCLASH_DIR/root/usr/share/openclash/"

awk '{
 if ($0 ~ /ls[[:space:]]+-l[[:space:]]+\/sys\/class\/net\/.*\|[[:space:]]*awk/) {
   print "for f in /sys/class/net/*;do echo ${f##*/};done";
   next
 }
 print
}' yml_change.sh > yml_change.sh.tmp && mv yml_change.sh.tmp yml_change.sh

echo "OOM fix applied"

# 返回 package
cd "$PKG_PATCH"

# NSS 修复
#NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
#[ -f "$NSS_DRV" ] && sed -i 's/START=.*/START=85/g' "$NSS_DRV"

#NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
#[ -f "$NSS_PBUF" ] && sed -i 's/START=.*/START=86/g' "$NSS_PBUF"

echo "All patches done"
