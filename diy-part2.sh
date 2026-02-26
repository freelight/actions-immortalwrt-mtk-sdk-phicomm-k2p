#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# ------------------------------- 原有修改：IP、主机名、802.11k/v/r -------------------------------
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/K2P/g' package/base-files/files/bin/config_generate

sed -i 's/RRMEnable=0/RRMEnable=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat || true
sed -i 's/RRMEnable=0/RRMEnable=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat || true
sed -i 's/FtSupport=0/FtSupport=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat || true
sed -i 's/FtSupport=0/FtSupport=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat || true
echo 'WNMEnable=1' >> package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat || true
echo 'WNMEnable=1' >> package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat || true

# ------------------------------- 添加 MTK HWNAT feed -------------------------------
if ! grep -q "mtk-openwrt-feeds" feeds.conf.default 2>/dev/null; then
    echo "src-git mtk https://git01.mediatek.com/plugins/gitiles/openwrt/feeds/mtk-openwrt-feeds" >> feeds.conf.default
fi

./scripts/feeds update -a
./scripts/feeds install -a

# ------------------------------- 添加所有第三方包 -------------------------------
# 1. iptvhelper
git clone https://github.com/riverscn/openwrt-iptvhelper.git package/luci-app-iptvhelper

# 2. omcproxy + luci-app-omcproxy (18.06分支)
git clone https://github.com/openwrt/omcproxy.git package/omcproxy
git clone -b 18.06 https://github.com/riverscn/luci-app-omcproxy.git package/luci-app-omcproxy

# 3. mwan3 + luci-app-mwan3 (从18.06分支)
mkdir -p package/net/mwan3_temp && cd package/net/mwan3_temp
git init && git remote add origin https://github.com/openwrt/packages.git
git fetch --depth 1 origin openwrt-18.06 && git sparse-checkout init --cone
git sparse-checkout set net/mwan3 && git checkout
mv net/mwan3/* ../../mwan3/ 2>/dev/null || true
cd ../../.. && rm -rf package/net/mwan3_temp

mkdir -p package/luci/luci-app-mwan3_temp && cd package/luci/luci-app-mwan3_temp
git init && git remote add origin https://github.com/openwrt/luci.git
git fetch --depth 1 origin openwrt-18.06 && git sparse-checkout init --cone
git sparse-checkout set applications/luci-app-mwan3 && git checkout
mv applications/luci-app-mwan3/* ../../luci-app-mwan3/ 2>/dev/null || true
cd ../../.. && rm -rf package/luci/luci-app-mwan3_temp

# 4. syncdial + macvlan
git clone https://github.com/rufengsuixing/luci-app-syncdial.git package/luci-app-syncdial

# 5. vlmcsd + luci-app-vlmcsd
git clone https://github.com/siwind/openwrt-vlmcsd.git package/vlmcsd
git clone https://github.com/siwind/luci-app-vlmcsd.git package/luci-app-vlmcsd

# 6. xupnpd + luci-app-xupnpd (从21.02历史)
mkdir -p package/multimedia/xupnpd_temp && cd package/multimedia/xupnpd_temp
git init && git remote add origin https://github.com/openwrt/packages.git
git fetch --depth 1 origin openwrt-21.02 && git sparse-checkout init --cone
git sparse-checkout set multimedia/xupnpd && git checkout
mv multimedia/xupnpd/* ../../xupnpd/ 2>/dev/null || true
cd ../../.. && rm -rf package/multimedia/xupnpd_temp
git clone https://github.com/jarod360/luci-app-xupnpd.git package/luci-app-xupnpd

# 7. ssr-plus
git clone https://github.com/immortalwrt-collections/luci-app-ssr-plus-Jo.git package/luci-app-ssr-plus

# 8. turboacc (chenmozhijin版 luci 分支，支持老 firewall3)
git clone -b luci https://github.com/chenmozhijin/turboacc.git package/luci-app-turboacc

# 9. ddns + luci-app-ddns (从18.06拉取)
mkdir -p package/luci/luci-app-ddns_temp && cd package/luci/luci-app-ddns_temp
git init && git remote add origin https://github.com/openwrt/luci.git
git fetch --depth 1 origin openwrt-18.06 && git sparse-checkout init --cone
git sparse-checkout set applications/luci-app-ddns && git checkout
mv applications/luci-app-ddns/* ../../luci-app-ddns/ 2>/dev/null || true
cd ../../.. && rm -rf package/luci/luci-app-ddns_temp

# 10. timewol (Lienol版 control-timewol)
git clone https://github.com/Lienol/openwrt-package.git package/luci-app-timewol-temp
mv package/luci-app-timewol-temp/luci-app-control-timewol package/luci-app-timewol
rm -rf package/luci-app-timewol-temp

# 11. arpbind (从 ImmortalWrt 或 wang1zhen fork)
git clone https://github.com/wang1zhen/openwrt-packages.git package/luci-app-arpbind-temp
mv package/luci-app-arpbind-temp/luci-app-arpbind package/luci-app-arpbind
rm -rf package/luci-app-arpbind-temp

# 12. ipt2socks (pexcn版)
git clone https://github.com/pexcn/openwrt-ipt2socks.git package/ipt2socks

# 13. ddns-scripts-cloudflare (官方 ddns-scripts 已支持cloudflare，可加自定义脚本；这里示例 clone 一个)
# git clone https://github.com/某仓库/cloudflare-ddns-script.git package/ddns-scripts-cloudflare  # 如需自定义脚本

# 14. zram-swap (从官方 openwrt 拉取)
mkdir -p package/system/zram-swap
cd package/system/zram-swap
wget -O Makefile https://raw.githubusercontent.com/openwrt/openwrt/master/package/system/zram-swap/Makefile
wget -O files/zram.init https://raw.githubusercontent.com/openwrt/openwrt/master/package/system/zram-swap/files/zram.init  # 如有
cd ../../..

# ipv6helper：未找到独立包，通常是自定义脚本或 odhcpd 配置；可手动在 .config 加相关，或忽略

# ------------------------------- 安装 feeds -------------------------------
./scripts/feeds install -a

# ------------------------------- .config 自定义 -------------------------------
cat >> .config << EOF
# 目标 & 驱动
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_phicomm_k2p=y
CONFIG_SWCONFIG=y
CONFIG_PACKAGE_kmod-swconfig=y
CONFIG_DSA=n

# iptables
CONFIG_PACKAGE_firewall=y
CONFIG_PACKAGE_iptables=y
CONFIG_PACKAGE_ip6tables=y
CONFIG_PACKAGE_firewall4=n

# 所有包
CONFIG_PACKAGE_luci-app-iptvhelper=y
CONFIG_PACKAGE_omcproxy=y
CONFIG_PACKAGE_luci-app-omcproxy=y
CONFIG_PACKAGE_mwan3=y
CONFIG_PACKAGE_luci-app-mwan3=y
CONFIG_PACKAGE_luci-app-syncdial=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_ppp=y
CONFIG_PACKAGE_ppp-mod-pppoe=y
CONFIG_PACKAGE_vlmcsd=y
CONFIG_PACKAGE_luci-app-vlmcsd=y
CONFIG_PACKAGE_xupnpd=y
CONFIG_PACKAGE_luci-app-xupnpd=y
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-timewol=y   # 或 CONFIG_PACKAGE_luci-app-control-timewol=y
CONFIG_PACKAGE_luci-app-arpbind=y
CONFIG_PACKAGE_ipt2socks=y
CONFIG_PACKAGE_zram-swap=y

# 基础
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
EOF

make defconfig
make defconfig

echo "diy-part2.sh 完成：已添加 iptvhelper omcproxy mwan3 syncdial vlmcsd xupnpd turboacc ddns wol arpbind ssr-plus ipt2socks ddns-cloudflare zram-swap 等"
