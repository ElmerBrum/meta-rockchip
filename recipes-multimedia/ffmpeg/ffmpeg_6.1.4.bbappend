# Swap ffmpeg's own source for nyanmisaka/ffmpeg-rockchip (branch "6.1",
# FFmpeg 6.1.6 per that branch's own RELEASE file - closest tracked
# branch to this recipe's 6.1.4) to get RKMPP decode/encode and RKRGA
# scale/vpp filter support - scoped to :radxa-zero-3e only, other
# machines keep vanilla ffmpeg.
#
# The base recipe's SRC_URI (release tarball + CVE/vulkan patches) is
# fully replaced rather than appended: the patches were cut against the
# release tarball's exact line numbers/context, which don't apply
# cleanly against a git checkout of a forked tree of a different
# lineage. Same approach as linux-rockchip_6.1.bbappend for the kernel.
#
# Built against the layer's existing vanilla rockchip-mpp/rockchip-librga
# (JeffyCN/mirrors, already confirmed working via dmesg) rather than
# nyanmisaka's own patched MPP/RGA forks (his build docs recommend those
# specifically, warning that a mismatched MPP "may cause undefined
# behavior") - deliberate choice to keep the already-tested driver/lib
# stack instead of forking it too. If ffmpeg's rkmpp/rkrga paths misbehave
# at runtime, this is the first thing to revisit.
SRC_URI:radxa-zero-3e = "git://github.com/nyanmisaka/ffmpeg-rockchip.git;protocol=https;nobranch=1;branch=6.1;"
SRCREV:radxa-zero-3e = "d547c18f18c744bc5e2180ce028fe1a6bd23ddad"
S:radxa-zero-3e = "${WORKDIR}/git"

# Only COPYING.LGPLv2.1 actually differs from the base recipe's
# checksum (byte-identical to upstream FFmpeg's own release/6.1 branch
# - the base recipe's checksum was just computed against the 6.1.4 tag
# specifically, and this branch has moved past that to 6.1.6). The
# other three license files are unchanged.
LIC_FILES_CHKSUM:radxa-zero-3e = "file://COPYING.GPLv2;md5=b234ee4d69f5fce4486a80fdaf4a4263 \
                    file://COPYING.GPLv3;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.LGPLv2.1;md5=eed22b3456132611e3d4aa7a7ec64dac \
                    file://COPYING.LGPLv3;md5=e6a600fd5e1d9cbde2d983680233ad02"

DEPENDS:append:radxa-zero-3e = " rockchip-mpp rockchip-librga"

# Required by ffmpeg-rockchip's own build docs (github.com/nyanmisaka/
# ffmpeg-rockchip, wiki "Compilation"): --enable-gpl --enable-version3
# --enable-libdrm --enable-rkmpp --enable-rkrga. "gpl" already exists as
# a PACKAGECONFIG flag in the base recipe (just not enabled by
# default); version3/libdrm/rkmpp/rkrga are new flags, since vanilla
# ffmpeg's ./configure doesn't have them at all.
PACKAGECONFIG[version3] = "--enable-version3,--disable-version3"
PACKAGECONFIG[libdrm] = "--enable-libdrm,--disable-libdrm,libdrm"
PACKAGECONFIG[rkmpp] = "--enable-rkmpp,--disable-rkmpp,rockchip-mpp"
PACKAGECONFIG[rkrga] = "--enable-rkrga,--disable-rkrga,rockchip-librga"

PACKAGECONFIG:append:radxa-zero-3e = " gpl version3 libdrm rkmpp rkrga"
