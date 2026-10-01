DESCRIPTION = "Rockchip RKNPU2 userspace runtime (librknnrt) and headers, \
for running .rknn models on the SoC's built-in NPU via the rknpu kernel \
driver (see IMAGE_REQUIREMENTS.md, NPU is already confirmed working)"
HOMEPAGE = "https://github.com/airockchip/rknn-toolkit2"
SECTION = "libs"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = "file://LICENSE;md5=a2399e2538b7ebeac89b5b1cc648459a"

# Prebuilt vendor blob - no source, no build. Individual files fetched
# directly (not the whole rknn-toolkit2 repo, which also bundles the
# multi-GB Python toolkit/model zoo) pinned to tag v2.3.2's commit.
RKNN_TOOLKIT2_COMMIT = "42aa1d426c0a9e0869b6374edba009f7208a1926"
RKNN_TOOLKIT2_BASE = "https://raw.githubusercontent.com/airockchip/rknn-toolkit2/${RKNN_TOOLKIT2_COMMIT}"

SRC_URI = " \
    ${RKNN_TOOLKIT2_BASE}/rknpu2/runtime/Linux/librknn_api/aarch64/librknnrt.so;name=librknnrt \
    ${RKNN_TOOLKIT2_BASE}/rknpu2/runtime/Linux/librknn_api/include/rknn_api.h;name=rknn_api_h \
    ${RKNN_TOOLKIT2_BASE}/rknpu2/runtime/Linux/librknn_api/include/rknn_custom_op.h;name=rknn_custom_op_h \
    ${RKNN_TOOLKIT2_BASE}/rknpu2/runtime/Linux/librknn_api/include/rknn_matmul_api.h;name=rknn_matmul_api_h \
    ${RKNN_TOOLKIT2_BASE}/LICENSE;name=license \
"
SRC_URI[librknnrt.sha256sum] = "d31fc19c85b85f6091b2bd0f6af9d962d5264a4e410bfb536402ec92bac738e8"
SRC_URI[rknn_api_h.sha256sum] = "c48e11a6f41b451a5fd1e4ad774ea60252d3d94f78bee9b21ea3d21b21deba9a"
SRC_URI[rknn_custom_op_h.sha256sum] = "af5983da0ca244ca31dc3162aa683322b0285531196c7a770f29cd2e3b8ccaa6"
SRC_URI[rknn_matmul_api_h.sha256sum] = "aaadd9a7118de30a06b222996b6731db77095d00f5931a7a98c83a67f14a4d42"
SRC_URI[license.sha256sum] = "d846f57d942c7dfdca7b8b54f9e8bb39e1e226790dc4f5ee205d6fd678961720"

S = "${WORKDIR}"

do_compile[noexec] = "1"

do_install () {
    install -d ${D}${libdir}
    install -m 0755 ${WORKDIR}/librknnrt.so ${D}${libdir}/librknnrt.so

    install -d ${D}${includedir}/rknpu
    install -m 0644 ${WORKDIR}/rknn_api.h ${D}${includedir}/rknpu/rknn_api.h
    install -m 0644 ${WORKDIR}/rknn_custom_op.h ${D}${includedir}/rknpu/rknn_custom_op.h
    install -m 0644 ${WORKDIR}/rknn_matmul_api.h ${D}${includedir}/rknpu/rknn_matmul_api.h
}

# Prebuilt, stripped, no SONAME/symlink versioning scheme (just
# "librknnrt.so" for both build and runtime) - headers+lib both go in
# the main package rather than splitting off a -dev, same reasoning as
# rockchip-libmali.bb in this layer.
#
# The default -dev package's FILES (${includedir}, ${libdir}/lib*.so)
# would otherwise claim both before FILES:${PN} below ever gets a
# chance - packages are populated in PACKAGES order and -dev comes
# before the main package - which is exactly what happened: everything
# landed in rknpu2-runtime-dev, and a private application library ended up RDEPENDS on a -dev
# package (QA error "rdepends on rknpu2-runtime-dev [dev-deps]").
FILES:${PN}-dev = ""

INSANE_SKIP:${PN} = "already-stripped ldflags dev-so"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"

FILES:${PN} = "${libdir}/librknnrt.so ${includedir}/rknpu"
