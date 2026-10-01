# Use Radxa's own kernel-6.1 BSP fork instead of this layer's default
# JeffyCN/mirrors source, scoped to :radxa-zero-3e only - no other
# machine in this layer is affected (they keep the layer's default
# 6.1.57).
#
# Why: 6.1.57 (the layer default, kernel-6.1 branch) hasn't moved in a
# while; radxa/kernel's linux-6.1-stan-rkr5.1 branch is at 6.1.115 (58
# more point-release-worth of upstream stable fixes) and is the same
# BSP lineage - rk3566.dtsi and rk3568-linux.dtsi were already
# confirmed byte-identical between the two forks when the board was
# first ported (see PORTING.md), and this branch is also where
# rk3566-radxa-zero3.dtsi/rk3566-radxa-zero-3e.dts were originally
# sourced from for the (now removed) 0004 backport patch - this source
# has them *natively*, backporting is no longer needed at all.
#
# 0005 (NPU enable) still applies here unmodified: it only appends to
# the end of rk3566-radxa-zero3.dtsi, and that file's content is
# unchanged between the two forks at these exact revisions (verified).
#
# Confirmed on a real build attempt: do_patch (0001-0003, 0005) and
# do_kernel_metadata/defconfig resolution all succeeded - do_compile
# got quite far into the tree before failing (see mali-jm.cfg below),
# which is itself good evidence the patches applied cleanly.
#
# mali-jm.cfg disables CONFIG_MALI_CSF_SUPPORT, which
# rockchip_linux_defconfig in this source sets to "y" - wrong for this
# board (see mali-jm.cfg's own comment) and also fatal to the build
# under Yocto's out-of-tree kbuild.
#
# mali-jm.cfg lives in linux-rockchip_6.1/ (alongside the 0001-0005
# patches) rather than the shared files/ dir - that's PATCHPATH's own
# naming convention (linux-rockchip.inc: "${BPN}_${LINUX_VERSION}",
# underscore), used only for *.patch auto-discovery. Plain file://
# SRC_URI entries go through bitbake's normal FILESPATH search instead,
# which uses "${BPN}-${PV}" (hyphen) - a different directory entirely -
# so it needs spelling out explicitly here.
FILESEXTRAPATHS:prepend := "${THISDIR}/linux-rockchip_6.1:"

SRC_URI:radxa-zero-3e = " \
	git://github.com/radxa/kernel.git;protocol=https;nobranch=1;branch=linux-6.1-stan-rkr5.1; \
	file://cgroups.cfg \
	file://mali-jm.cfg \
"
SRCREV:radxa-zero-3e = "f87fca6cefcb6229c7f81399dd351cf658940bfa"
