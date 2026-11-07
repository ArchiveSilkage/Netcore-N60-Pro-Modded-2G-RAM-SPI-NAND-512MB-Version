**English** | [中文](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

# Actions-OpenWrt

[![LICENSE](https://img.shields.io/github/license/mashape/apistatus.svg?style=flat-square&label=LICENSE)](https://github.com/P3TERX/Actions-OpenWrt/blob/master/LICENSE)
![GitHub Stars](https://img.shields.io/github/stars/P3TERX/Actions-OpenWrt.svg?style=flat-square&label=Stars&logo=github)
![GitHub Forks](https://img.shields.io/github/forks/P3TERX/Actions-OpenWrt.svg?style=flat-square&label=Forks&logo=github)

A template for building OpenWrt with GitHub Actions

## Usage

- 点击 [Fork] 按钮生成新项目.
- [LEDE源码](https://github.com/coolsnowwolf/lede)，自定义脚本diy-part2.sh，配置文件LEDE.config.
- [dailook源码](https://github.com/dailook/immortalwrt-mt798x)，自定义脚本diy-part3.sh，配置文件dailook-hanwckf.config.该源码适配了硬改后的512M闪存，如果需要编译512M的ROM，需要在dailook-hanwckf.config文件里面添加如下内容：
 ```bash
CONFIG_TARGET_DEVICE_mediatek_mt7986_DEVICE_netcore_n60pro-512rom=y
CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7986_DEVICE_netcore_n60pro-512rom=""
```
- [Immortalwrt源码](https://github.com/immortalwrt/immortalwrt)，自定义脚本diy-part4.sh，配置文件immortalwrt.config.
- [237源码](https://github.com/padavanonly/immortalwrt-mt798x-24.10)，6.6内核自定义脚本diy-part5-6.6.sh，配置文件padavanonly-immortalwrt-mt798x-6.6.config，5.4内核版本自定义脚本diy-part5-2410.sh，配置文件padavanonly-immortalwrt-mt798x-2410.config.
- [chasey-dev源码](https://github.com/chasey-dev/immortalwrt-mt798x-rebase)（ImmortalWrt 25.12基线 + 6.12内核，MTK mt_wifi 7.6.7.3 + HNAT），自定义脚本diy-part6-25.12.sh，配置文件chasey-immortalwrt-mt798x-25.12.config，feeds文件feeds.conf.default.chasey（istore/nikki feed，helloworld由diy-part1.sh追加）.硬改机（512MB SPI NAND + 2GB RAM）的DTS适配已内置在diy-part6-25.12.sh中（ubi分区填满0x1fa80000 + 内存2GB），产物为FIT格式sysupgrade.itb，可用WildEdition U-Boot直接刷入.
- diy-part1.sh是共用脚本，加入了ADGuardHome源码，所有默认配置文件只集成了定时重启、终端ttyd、组播代理omcproxy、组播转换msd_lite和ADGuardHome的luci，需要自定义的请自行修改对应的自定义脚本和配置文件.
- ADGuardHome正常使用需要在luci里面手动下载[Linux_arm64核心文件](https://github.com/AdguardTeam/AdGuardHome/releases/),或者PC下载后解压将AdGuardHome上传至/usr/bin/AdGuardHome/，设置权限0755.
- 在Actions页面运行对应的源码固件编译文件，点击右侧的 Run workflow 按钮开始编译，正常的话大概1-2h左右能看到编译结果，编译完成后下载相应的固件即可.

## Tips

- It may take a long time to create a `.config` file and build the OpenWrt firmware. Thus, before create repository to build your own firmware, you may check out if others have already built it which meet your needs by simply [search `Actions-Openwrt` in GitHub](https://github.com/search?q=Actions-openwrt).
- Add some meta info of your built firmware (such as firmware architecture and installed packages) to your repository introduction, this will save others' time.

## Credits

- [Microsoft Azure](https://azure.microsoft.com)
- [GitHub Actions](https://github.com/features/actions)
- [OpenWrt](https://github.com/openwrt/openwrt)
- [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
- [Mikubill/transfer](https://github.com/Mikubill/transfer)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
- [Mattraks/delete-workflow-runs](https://github.com/Mattraks/delete-workflow-runs)
- [dev-drprasad/delete-older-releases](https://github.com/dev-drprasad/delete-older-releases)
- [peter-evans/repository-dispatch](https://github.com/peter-evans/repository-dispatch)

## License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/main/LICENSE) © [**P3TERX**](https://p3terx.com)
