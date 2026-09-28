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
# NOT build-tested yet. 0001-0003 (the layer's existing generic hack
# patches, unrelated to this board) were checked by hand against this
# source's actual file content before switching - do_mounts.c is
# byte-identical; the two drm rockchip cursor-hack patches target
# lines that shifted position (2400->2411 in rockchip_drm_vop.c) but
# matched context text exactly, which `git am`/patch context-matching
# should tolerate - not a certainty until it's actually applied.
SRC_URI:radxa-zero-3e = " \
	git://github.com/radxa/kernel.git;protocol=https;nobranch=1;branch=linux-6.1-stan-rkr5.1; \
	file://cgroups.cfg \
"
SRCREV:radxa-zero-3e = "f87fca6cefcb6229c7f81399dd351cf658940bfa"
