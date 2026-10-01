# Copyright (c) 2026, Elmer
# Released under the MIT license (see COPYING.MIT for the terms)
#
# U-Boot for the Radxa ZERO 3E (RK3566).
#
# u-boot-rockchip.bb (the default virtual/bootloader provider in this
# layer) is built around the legacy 2017.09 Rockchip SDK fork + "make.sh"
# Miniloader wrapper, which never gained ZERO 3 family support. Real
# board support (SPL/TPL, PMIC, eMMC/SD pinmux, board_fit_config_name_match
# auto-detection between ZERO 3 / 3W / 3E) only exists in mainline-style
# U-Boot from 2024 onward.
#
# We build from the same source the upstream/official meta-rockchip
# (git.yoctoproject.org/meta-rockchip) layer uses for this exact board:
# Kwiboo's mainline-based fork, branch rk3xxx-2024.07. See:
#   https://www.mail-archive.com/u-boot@lists.denx.de/msg516456.html
#   ("[PATCH 0/5] board: rockchip: Add Radxa ZERO 3W/3E")
#
# This recipe deliberately does NOT reuse u-boot-rockchip.bb's do_compile
# (the RK "make.sh" wrapper does not exist in this tree at all - it is a
# plain mainline U-Boot Kbuild tree). Instead it relies on the stock
# u-boot.bbclass configure/compile flow, only supplying the prebuilt
# BL31 (ATF) and TPL (DDR init) blobs mainline U-Boot expects via the
# BL31/ROCKCHIP_TPL make variables, sourced from the same rkbin blob
# tree u-boot-rockchip.bb already uses (those blobs are generic per-SoC,
# not per-board, and RK3566 reuses the RK3568 BL31/BL32).
#
# Output artifacts are deliberately renamed/symlinked to "idblock.img"
# and "uboot.img" so they drop into the existing generic-gptdisk.wks.in
# / rockchip-image.bbclass machinery unmodified: do_fixup_wks in
# rockchip-image.bbclass already tolerates a missing "trust.img" (not
# needed here - BL31/OP-TEE are embedded straight into the u-boot.itb
# FIT image instead of a separate trust partition).
#
# KNOWN RISK / NOT BUILD-TESTED: this recipe was written from verified
# upstream sources (pinned SRCREVs, confirmed defconfig content, and the
# official meta-rockchip's own u-boot-rockchip.inc as a reference) but
# has not been compiled. The DEPENDS list below covers the common
# mainline Rockchip U-Boot FIT/binman toolchain; expect to iterate on it
# on first real build. See PORTING.md at the top of the repository.

require recipes-bsp/u-boot/u-boot.inc
require recipes-bsp/u-boot/u-boot-common.inc

SUMMARY = "U-Boot (mainline) for the Radxa ZERO 3E"

PROVIDES = "virtual/bootloader"
COMPATIBLE_MACHINE = "radxa-zero-3e"

# LICENSE/LIC_FILES_CHKSUM are inherited from u-boot-common.inc; the
# Licenses/README checksum happens to match this tree too (verified).

DEPENDS += "dtc-native bc-native python3-pyelftools-native openssl-native"

PV = "2024.07"

# NOTE: Kwiboo/u-boot-rockchip's rk3xxx-2024.07 is a personal WIP branch,
# not a stable tag - it gets rebased/force-pushed from time to time, which
# can make a pinned SRCREV unreachable ("Unable to find revision ... even
# from upstream"). If that happens, re-pin to the branch's current tip
# (re-verify configs/radxa-zero-3-rk3566_defconfig and Licenses/README's
# checksum still match before doing so - see PORTING.md).
SRCREV = "2e2ae1fb69a25217640bfe2fb9abaf9f4fbacead"
SRCREV_rkbin = "c41b714cacd249e3ef69b2bbe774da5095eefd72"
SRC_URI = " \
	git://github.com/Kwiboo/u-boot-rockchip.git;protocol=https;branch=rk3xxx-2024.07 \
	git://github.com/JeffyCN/mirrors.git;protocol=https;branch=rkbin;name=rkbin;destsuffix=rkbin \
"
SRCREV_FORMAT = "default_rkbin"

UBOOT_MACHINE = "radxa-zero-3-rk3566_defconfig"
UBOOT_SUFFIX = "itb"
UBOOT_ENTRYPOINT = "0x06000000"

# RK3566 reuses the RK3568 BL31/BL32 blobs (this is not a typo - see
# rockchip-linux/rkbin's own doc/release/RK3566_EN.md).
do_compile:prepend() {
	export BL31="$(ls ${WORKDIR}/rkbin/bin/rk35/rk3568_bl31_v*.elf | sort -V | tail -n1)"
	export ROCKCHIP_TPL="$(ls ${WORKDIR}/rkbin/bin/rk35/rk3566_ddr_1056MHz_v*.bin | sort -V | tail -n1)"

	if [ -z "${BL31}" ] || [ -z "${ROCKCHIP_TPL}" ]; then
		bbfatal "Could not find rk3568 BL31 and/or rk3566 DDR blobs in rkbin checkout"
	fi
}

do_deploy:append() {
	if [ -f "${B}/idbloader.img" ]; then
		install -m 0644 "${B}/idbloader.img" "${DEPLOYDIR}/idblock.img-${PV}"
		ln -sf "idblock.img-${PV}" "${DEPLOYDIR}/idblock.img"
	fi
	if [ -f "${B}/u-boot.itb" ]; then
		install -m 0644 "${B}/u-boot.itb" "${DEPLOYDIR}/uboot.img-${PV}"
		ln -sf "uboot.img-${PV}" "${DEPLOYDIR}/uboot.img"
	fi
}
