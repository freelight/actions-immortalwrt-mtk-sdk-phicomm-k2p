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
# Modify default IP
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# Modify default Hostname
sed -i 's/ImmortalWrt/K2P/g' package/base-files/files/bin/config_generate

# Enable 802.11k/v/r (针对 mt7615 WiFi 驱动配置文件)
sed -i 's/RRMEnable=0/RRMEnable=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat
sed -i 's/RRMEnable=0/RRMEnable=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat
sed -i 's/FtSupport=0/FtSupport=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat
sed -i 's/FtSupport=0/FtSupport=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat
echo 'WNMEnable=1' >> package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat || true
echo 'WNMEnable=1' >> package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat || true

# ------------------------------- 添加 MTK HWNAT feed（保险起见，即使上游有也再确认） -------------------------------
if ! grep -q "mtk-openwrt-feeds" feeds.conf.default 2>/dev/null; then
    echo "src-git mtk https://git01.mediatek.com/plugins/gitiles/openwrt/feeds/mtk-openwrt-feeds" >> feeds.conf.default
    echo "已添加 MTK HWNAT feed 到 feeds.conf.default"
fi

# 确保 feed 更新与安装（workflow 通常已执行，但这里再跑一次无害）
./scripts/feeds update -a
./scripts/feeds install -a

# ------------------------------- 自定义 .config（你的核心要求） -------------------------------
cat > .config.custom << 'EOF'
# 目标设备：斐讯 K2P (ramips/mt7621)
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_phicomm_k2p=y

# 明确使用 Switch 驱动（swconfig），禁用 DSA
CONFIG_SWCONFIG=y
CONFIG_PACKAGE_kmod-swconfig=y
CONFIG_DSA=n
CONFIG_NET_DSA=n
CONFIG_TARGET_ramips_MT7621_DSA=n

# 强制使用 iptables + firewall，禁用 nftables/firewall4
CONFIG_PACKAGE_firewall=y
CONFIG_PACKAGE_iptables=y
CONFIG_PACKAGE_iptables-mod-conntrack-extra=y
CONFIG_PACKAGE_iptables-mod-ipopt=y
CONFIG_PACKAGE_ip6tables=y
CONFIG_PACKAGE_firewall4=n
CONFIG_PACKAGE_nftables=n
CONFIG_PACKAGE_kmod-nft-*=n

# 你要求的全部 luci-app 包（全部编译进固件）
CONFIG_PACKAGE_luci-app-iptvhelper=y
CONFIG_PACKAGE_luci-app-msd_lite=y
CONFIG_PACKAGE_luci-app-xupnpd=y
CONFIG_PACKAGE_luci-app-omcproxy=y
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_PACKAGE_luci-app-vlmcsd=y
CONFIG_PACKAGE_luci-app-socat=y
CONFIG_PACKAGE_luci-app-timewol=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-mwan3=y
CONFIG_PACKAGE_luci-app-syncdial=y
CONFIG_PACKAGE_luci-app-ssr-plus=y

# 推荐附带（可选，根据需要注释）
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
EOF

# 合并自定义配置（如果已有 .config，先备份）
[ -f .config ] && mv .config .config.bak-$(date +%s)
mv .config.custom .config

# 加载配置 + 扩展依赖
make defconfig

# 再次 defconfig（确保所有依赖被正确拉取）
make defconfig

echo "diy-part2.sh 执行完成："
echo "  - 默认 IP 已改为 192.168.2.1"
echo "  - 主机名已改为 K2P"
echo "  - 802.11k/v/r 已启用"
echo "  - MTK HWNAT feed 已添加"
echo "  - swconfig 强制启用，DSA 已禁用"
echo "  - iptables/firewall 强制使用，nftables/firewall4 已禁用"
echo "  - 所有指定 luci-app 已选中"
