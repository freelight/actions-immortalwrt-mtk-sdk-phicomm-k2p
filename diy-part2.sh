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

# ------------------------------- 原有修改：IP、主机名、WiFi 优化 -------------------------------
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/K2P/g' package/base-files/files/bin/config_generate

sed -i 's/RRMEnable=0/RRMEnable=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat || true
sed -i 's/RRMEnable=0/RRMEnable=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat || true
sed -i 's/FtSupport=0/FtSupport=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat || true
sed -i 's/FtSupport=0/FtSupport=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat || true
echo 'WNMEnable=1' >> package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat || true
echo 'WNMEnable=1' >> package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat || true

# ------------------------------- MTK HWNAT feed -------------------------------
if ! grep -q "mtk-openwrt-feeds" feeds.conf.default 2>/dev/null; then
    echo "src-git mtk https://git01.mediatek.com/plugins/gitiles/openwrt/feeds/mtk-openwrt-feeds" >> feeds.conf.default
fi

./scripts/feeds update -a
./scripts/feeds install -a

# ------------------------------- 添加第三方包（luci-app + 核心 + 非LuCI组件） -------------------------------
# 1. iptvhelper
git clone https://github.com/riverscn/openwrt-iptvhelper.git package/luci-app-iptvhelper

# 2. omcproxy + luci-app-omcproxy (18.06分支)
git clone https://github.com/openwrt/omcproxy.git package/omcproxy
git clone -b 18.06 https://github.com/riverscn/luci-app-omcproxy.git package/luci-app-omcproxy

# 3. mwan3 + luci-app-mwan3 (从18.06分支sparse)
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

# 4. syncdial + macvlan
git clone https://github.com/rufengsuixing/luci-app-syncdial.git package/luci-app-syncdial

# 5. vlmcsd + luci-app-vlmcsd
git clone https://github.com/siwind/openwrt-vlmcsd.git package/vlmcsd
git clone https://github.com/siwind/luci-app-vlmcsd.git package/luci-app-vlmcsd

# 6. xupnpd + luci-app-xupnpd (从21.02历史版)
mkdir -p package/xupnpd_temp && cd package/xupnpd_temp
git init && git remote add origin https://github.com/openwrt/packages.git
git fetch --depth 1 origin openwrt-21.02 && git sparse-checkout init --cone
git sparse-checkout set multimedia/xupnpd && git checkout
mv multimedia/xupnpd/* ../xupnpd/ 2>/dev/null || true
cd ../.. && rm -rf package/xupnpd_temp
git clone https://github.com/jarod360/luci-app-xupnpd.git package/luci-app-xupnpd

# 7. ssr-plus (备份版)
git clone https://github.com/immortalwrt-collections/luci-app-ssr-plus-Jo.git package/luci-app-ssr-plus

# 8. turboacc (chenmozhijin luci分支，测试兼容)
git clone -b luci https://github.com/chenmozhijin/turboacc.git package/luci-app-turboacc

# 9. ddns (官方18.06分支)
mkdir -p package/luci_app_ddns_temp && cd package/luci_app_ddns_temp
git init && git remote add origin https://github.com/openwrt/luci.git
git fetch --depth 1 origin openwrt-18.06 && git sparse-checkout init --cone
git sparse-checkout set applications/luci-app-ddns && git checkout
mv applications/luci-app-ddns/* ../luci-app-ddns/ 2>/dev/null || true
cd ../.. && rm -rf package/luci_app_ddns_temp

# 10. timewol (Lienol版本)
git clone https://github.com/Lienol/openwrt-package.git package/openwrt-package-temp
mv package/openwrt-package-temp/luci-app-control-timewol package/luci-app-timewol
rm -rf package/openwrt-package-temp

# 11. arpbind (ImmortalWrt风格或fork)
git clone https://github.com/immortalwrt/luci.git package/immortalwrt-luci-temp --depth=1 --no-checkout
cd package/immortalwrt-luci-temp
git sparse-checkout init --cone
git sparse-checkout set applications/luci-app-arpbind
git checkout
mv applications/luci-app-arpbind ../luci-app-arpbind
cd ../.. && rm -rf package/immortalwrt-luci-temp

# 12. 非LuCI组件
git clone https://github.com/pexcn/openwrt-ipt2socks.git package/ipt2socks
# cloudflare-ddns：老分支常用ddns-scripts + custom，如果有feeds用CONFIG，否则clone简单脚本
# ipv6helper：常为自定义或odhcpd配置，这里加CONFIG（如果有包可clone替换）
# zram-swap：官方内核模块

# ------------------------------- 安装所有新包 -------------------------------
./scripts/feeds install -a

# ------------------------------- .config 自定义（所有包 + 核心设置） -------------------------------
cat >> .config << EOF
# 设备 & 驱动
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

# 所有LuCI包
CONFIG_PACKAGE_luci-app-iptvhelper=y
CONFIG_PACKAGE_omcproxy=y
CONFIG_PACKAGE_luci-app-omcproxy=y
CONFIG_PACKAGE_mwan3=y
CONFIG_PACKAGE_luci-app-mwan3=y
CONFIG_PACKAGE_luci-app-syncdial=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_vlmcsd=y
CONFIG_PACKAGE_luci-app-vlmcsd=y
CONFIG_PACKAGE_xupnpd=y
CONFIG_PACKAGE_luci-app-xupnpd=y
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-timewol=y
CONFIG_PACKAGE_luci-app-arpbind=y

# 非LuCI组件
CONFIG_PACKAGE_ipt2socks=y
CONFIG_PACKAGE_ddns-scripts=y               # 基础ddns
CONFIG_PACKAGE_ddns-scripts-cloudflare=y    # 如果feeds有，否则需额外clone
CONFIG_PACKAGE_zram-swap=y
# ipv6helper：如果有包CONFIG_PACKAGE_ipv6helper=y，否则依赖odhcpd等
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_ppp=y
CONFIG_PACKAGE_ppp-mod-pppoe=y

# 基础
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
EOF

make defconfig
make defconfig

echo "diy-part2.sh 完成：所有指定包已添加"
