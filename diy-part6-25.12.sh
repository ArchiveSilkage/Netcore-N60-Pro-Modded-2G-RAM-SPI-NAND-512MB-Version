#!/bin/bash
#
# File name: diy-part6-25.12.sh
# Description: DIY script for chasey-dev/immortalwrt-mt798x-rebase (25.12)
#              Runs after feeds install, before defconfig.
#
# 适用于磊科 N60 Pro 硬改机：2GB RAM + 512MB SPI NAND（W25N04KV，WildEdition U-Boot）
#

DTS=target/linux/mediatek/dts/mt7986a-netcore-n60-pro.dts

# 硬改 DTS 适配：
# 1) 内存 512MB -> 2GB
# 2) ubi 分区扩到 0x1fa80000（506.5MB，填满 512MB 闪存，
#    与现役 6.6 固件的 mtd 分区表及 fork 里 b1ef7fa8 的改法一致）
sed -i 's/reg = <0 0x40000000 0 0x20000000>;/reg = <0 0x40000000 0 0x80000000>;/' $DTS
sed -i 's/reg = <0x0580000 0x7a80000>;/reg = <0x0580000 0x1fa80000>;/' $DTS
grep -q 'reg = <0 0x40000000 0 0x80000000>;' $DTS || { echo 'ERROR: memory hardmod patch failed'; exit 1; }
grep -q 'reg = <0x0580000 0x1fa80000>;' $DTS || { echo 'ERROR: ubi hardmod patch failed'; exit 1; }

# 注：chasey 25.12 分支只有 netcore_n60-pro（FIT/ubootmod）设备块，
# 不存在 netcore_n60-pro-mtkuboot（Issue #143 仅涉及 dev 分支），无需处理。

# 移除 LuCI 捆绑的在线升级（attendedsysupgrade），恩山帖建议勿用
sed -i '/attendedsysupgrade/d' feeds/luci/collections/luci/Makefile

# 添加组播防火墙规则（IPTV，与其它管线一致）
cat >> package/network/config/firewall/files/firewall.config <<EOF
config rule
        option name 'Allow-UDP-igmpproxy'
        option src 'wan'
        option dest 'lan'
        option dest_ip '224.0.0.0/4'
        option proto 'udp'
        option target 'ACCEPT'
        option family 'ipv4'

config rule
        option name 'Allow-UDP-udpxy'
        option src 'wan'
        option dest_ip '224.0.0.0/4'
        option proto 'udp'
        option target 'ACCEPT'
EOF
