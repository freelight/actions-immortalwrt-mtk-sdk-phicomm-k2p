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

# ------------------------------- 原有修改：默认 IP、主机名、802.11k/v/r -------------------------------
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/K2P/g' package/base-files/files/bin/config_generate

# Enable 802.11k/v/r
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

# ------------------------------- 添加所有第三方包（luci-app + 核心） -------------------------------
# 1. luci-app-iptvhelper
git clone https://github.com/riverscn/openwrt-iptvhelper.git package/luci-app-iptvhelper

# 2. omcproxy + luci-app-omcproxy (18.06 兼容)
git clone https://github.com/openwrt/omcproxy.git package/omcproxy
git clone -b 18.06 https://github.com/riverscn/luci-app-omcproxy.git package/luci-app-omcproxy

# 3. mwan3 + luci-app-mwan3 (官方 18.06 分支)
mkdir -p package/mwan3_temp && cd package/mwan3_temp
git init && git remote add origin https://github.com/openwrt/packages.git
git fetch --depth 1 origin openwrt-18.06 && git sparse-checkout init --cone
git sparse-checkout set net/mwan3 && git checkout
mv net/mwan3/* ../mwan3/ 2>/dev/null || true
cd ../.. && rm -rf package/mwan3_temp

mkdir -p package/luci_mwan3_temp && cd package/luci_mwan3_temp
git init && git remote add origin https://github.com/openwrt/luci.git
git fetch --depth 1 origin openwrt-18.06 && git sparse-checkout init --cone
git sparse-checkout set applications/luci-app-mwan3 && git checkout
mv applications/luci-app-mwan3/* ../luci-app-mwan3/ 2>/dev/null || true
cd ../.. && rm -rf package/luci_mwan3_temp

# 4. luci-app-syncdial + kmod-macvlan
git clone https://github.com/rufengsuixing/luci-app-syncdial.git package/luci-app-syncdial

# 5. vlmcsd + luci-app-vlmcsd
git clone https://github.com/siwind/openwrt-vlmcsd.git package/vlmcsd
git clone https://github.com/siwind/luci-app-vlmcsd.git package/luci-app-vlmcsd

# 6. xupnpd + luci-app-xupnpd (历史 21.02 分支)
mkdir -p package/xupnpd_temp && cd package/xupnpd_temp
git init && git remote add origin https://github.com/openwrt/packages.git
git fetch --depth 1 origin openwrt-21.02 && git sparse-checkout init --cone
git sparse-checkout set multimedia/xupnpd && git checkout
mv multimedia/xupnpd/* ../xupnpd/ 2>/dev/null || true
cd ../.. && rm -rf package/xupnpd_temp
git clone https://github.com/jarod360/luci-app-xupnpd.git package/luci-app-xupnpd

# 7. luci-app-ssr-plus (备份版)
git clone https://github.com/immortalwrt-collections/luci-app-ssr-plus-Jo.git package/luci-app-ssr-plus

# 8. luci-app-turboacc (chenmozhijin 版，luci 分支)
git clone -b luci https://github.com/chenmozhijin/turboacc.git package/luci-app-turboacc

# 9. luci-app-ddns (官方 18.06 分支)
mkdir -p package/luci_ddns_temp && cd package/luci_ddns_temp
git init && git remote add origin https://github.com/openwrt/luci.git
git fetch --depth 1 origin openwrt-18.06 && git sparse-checkout init --cone
git sparse-checkout set applications/luci-app-ddns && git checkout
mv applications/luci-app-ddns/* ../luci-app-ddns/ 2>/dev/null || true
cd ../.. && rm -rf package/luci_ddns_temp

# 10. luci-app-wol (官方 luci-app-wol，支持 Wake-on-LAN / timewol)
mkdir -p package/luci_wol_temp && cd package/luci_wol_temp
git init && git remote add origin https://github.com/openwrt/luci.git
git fetch --depth 1 origin openwrt-18.06 && git sparse-checkout init --cone
git sparse-checkout set applications/luci-app-wol && git checkout
mv applications/luci-app-wol/* ../luci-app-wol/ 2>/dev/null || true
cd ../.. && rm -rf package/luci_wol_temp

# 11. luci-app-arpbind (ImmortalWrt 或兼容 fork)
git clone https://github.com/immortalwrt/luci.git package/luci_arpbind_temp --depth=1 --branch master --single-branch
cd package/luci_arpbind_temp
git sparse-checkout init --cone
git sparse-checkout set applications/luci-app-arpbind
git checkout
mv applications/luci-app-arpbind ../luci-app-arpbind 2>/dev/null || true
cd ../.. && rm -rf package/luci_arpbind_temp

# ------------------------------- 安装所有新 package -------------------------------
./scripts/feeds install -a

# ------------------------------- 自定义 .config -------------------------------
cat >> .config << EOF
# 目标 & 驱动
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_phicomm_k2p=y
CONFIG_SWCONFIG=y
CONFIG_PACKAGE_kmod-swconfig=y
CONFIG_DSA=n
CONFIG_NET_DSA=n

# iptables 强制
CONFIG_PACKAGE_firewall=y
CONFIG_PACKAGE_iptables=y
CONFIG_PACKAGE_ip6tables=y
CONFIG_PACKAGE_firewall4=n
CONFIG_PACKAGE_nftables=n

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
CONFIG_PACKAGE_luci-app-wol=y
CONFIG_PACKAGE_luci-app-arpbind=y

# 基础 luci
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
EOF

# 两次 defconfig 确保依赖完整
make defconfig
make defconfig

echo "diy-part2.sh 执行完成：所有指定包已添加"
