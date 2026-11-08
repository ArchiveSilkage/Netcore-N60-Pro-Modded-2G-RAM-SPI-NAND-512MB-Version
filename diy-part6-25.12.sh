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

# luci-app-cpu-status：chasey 树与全部 feeds 均无此包（唯一上游 gSpotx2f，支持 25.12），
# 克隆进树；不放入共享的 diy-part1.sh，避免与 6.6 管线的 padavanonly 内置版重名冲突
git clone --depth 1 https://github.com/gSpotx2f/luci-app-cpu-status package/luci-app-cpu-status \
	|| { echo 'ERROR: clone luci-app-cpu-status failed'; exit 1; }

# iStore：不走 feed（索引机制在本树静默丢弃 luci-app-store，见 run#5-#7 取证），
# 直接克隆入树；同时去掉 +tar 依赖（busybox tar 已覆盖，GNU tar 的 feed 包
# 在本树同样无法生成 Kconfig 符号，一并入树试验）
git clone --depth 1 https://github.com/istoreos/istore /tmp/istore-src \
	|| { echo 'ERROR: clone istore failed'; exit 1; }
for d in luci-app-store luci-lib-taskd luci-lib-xterm taskd; do
	if [ -d /tmp/istore-src/luci/$d ]; then
		cp -r /tmp/istore-src/luci/$d package/
	elif [ -d /tmp/istore-src/$d ]; then
		cp -r /tmp/istore-src/$d package/
	else
		echo "ERROR: istore component $d not found"; exit 1
	fi
done
sed -i 's/ +tar//' package/luci-app-store/Makefile
git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages /tmp/pkgs-src \
	|| { echo 'ERROR: clone packages feed failed'; exit 1; }
git -C /tmp/pkgs-src sparse-checkout set utils/tar
cp -r /tmp/pkgs-src/utils/tar package/tar

# SanDisk CZ80 (0781:5580) 诊断结论（2026-11-07）：设备以 BOT(usb-storage) 正常绑定并挂载，
# 无 UAS 兼容问题，无需烘焙 usb-storage.quirks；旧固件"不识别"系缺 kmod-fs-exfat（config 已补）。

# 默认 LAN IP 改为 192.168.6.1（含 DHCP 起始段 192.168.6.100）
sed -i 's/192\.168\.1\.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# USB3 SS 链路问题（run#8 后实测）：SS 训练能通过但 SetAddress 全部超时
# （error -62/-71），且 6.12 内核不再像 6.6 那样自动回落 HS 总线 → USB3 设备
# 彻底不识别、USB2 设备正常。旧 6.6 固件上 CZ80 实际也是 SS 失败回落 480M HS。
# 板级 dts 覆盖 &ssusb 的 phys：去掉 U3 PHY 引用，保留两个 USB2 端口，
# 使所有 USB 设备（含 USB3 盘）直接以 HS 480M 枚举，行为与旧固件一致。
sed -i '/^&ssusb {/,/^};/s/\tstatus = "okay";/\tstatus = "okay";\n\tphys = <\&u2port0 PHY_TYPE_USB2>, <\&u2port1 PHY_TYPE_USB2>;/' \
	target/linux/mediatek/dts/mt7986a-netcore-n60-pro.dts
grep -q "u2port1 PHY_TYPE_USB2" target/linux/mediatek/dts/mt7986a-netcore-n60-pro.dts \
	|| { echo 'ERROR: ssusb phys override failed'; exit 1; }

# AdGuardHome luci 更新脚本适配 25.12（apk 时代无 opkg，实测报错 line 121）：
# 1) 架构判定改用 uname -m（aarch64 -> arm64 分支脚本自带）
AGH_SH=package/luci-app-adguardhome/root/usr/share/AdGuardHome/update_core.sh
sed -i '/opkg info kernel/c\Archt="$(uname -m)"' $AGH_SH
# 2) 可选 upx 压缩路径里的 xz 自举 opkg 改 apk（默认不启用 upx，不影响主流程）
sed -i '/opkg install xz/c\ \twhich xz || apk add xz || (echo "xz download fail" \&\& EXIT 1)' $AGH_SH
grep -q "opkg info kernel" $AGH_SH && { echo 'ERROR: AdGuardHome update_core.sh adapt failed'; exit 1; }
# 3) AGH 出厂即走 dnsmasq 转发模式（AGH DNS 挪 :54，dnsmasq:53 转发 127.0.0.1#54；
#    核心二进制需刷机后手动安装或经 luci「更新核心」下载）
AGH_UCI=package/luci-app-adguardhome/root/etc/config/AdGuardHome
if [ -f $AGH_UCI ]; then
	sed -i "s/option redirect 'none'/option redirect 'dnsmasq'/" $AGH_UCI
	grep -q "redirect 'dnsmasq'" $AGH_UCI || { echo 'ERROR: AdGuardHome uci redirect patch failed'; exit 1; }
fi

# IPv6 扩展前缀方案调优（ISP 仅下发 /64 无 PD，RFC 7278）：
# 1) 关闭 WAN6 源过滤——sourcefilter=1（默认）会把默认路由按源地址复制成
#    带 from 约束的路由（metric 384/640 = RA 优先级换算值），实测压过 LAN 侧
#    任何 metric 的路由（Linux v6 FIB 对源约束路由的优先处理），导致下游
#    /64 内互访被扔给上游网关。关闭后合并为一条普通默认路由，metric 语义恢复。
# 2) LAN 侧 ra_default=1——规避 odhcpd #388（源特定默认路由被判"无默认路由"
#    导致 LAN RA lifetime=0），保证下游始终有 v6 网关。
# 3) wan6 master + 两端 NDP relay——RFC 7278 要求的 NDP 代理，保上游回程可达
#    （与 LAN server 模式共存，odhcpd 三服务彼此独立）。
# 以上全部来自实测 + odhcpd #388/#23246/openwrt wiki 取证（2026-11-08）。
UD=files/etc/uci-defaults
mkdir -p $UD
cat > $UD/99-n60pro-ipv6-agh <<'EOF'
#!/bin/sh
# N60 Pro: IPv6 extendprefix tuning + AdGuardHome dnsmasq-forward
uci -q set network.wan6.sourcefilter='0'
uci -q commit network
uci -q get dhcp.wan6 >/dev/null || { uci -q add dhcp wan6; uci -q rename dhcp.@dhcp[-1]='wan6'; }
uci -q set dhcp.wan6.master='1'
uci -q set dhcp.wan6.ndp='relay'
uci -q set dhcp.lan.ra_default='1'
uci -q set dhcp.lan.ndp='relay'
uci -q commit dhcp
uci -q get AdGuardHome.AdGuardHome >/dev/null && {
	uci -q set AdGuardHome.AdGuardHome.redirect='dnsmasq'
	uci -q commit AdGuardHome
}
exit 0
EOF

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
