# SDL2's default PACKAGECONFIG (poky/meta/recipes-graphics/libsdl2)
# only enables video backends derived from DISTRO_FEATURES (opengl,
# wayland, x11...) - none of which work here, since there's no X
# server or Wayland compositor on this image (direct KMS/DRM only,
# confirmed working via modetest - see HDMI entry in
# IMAGE_REQUIREMENTS.md). "kmsdrm" isn't DISTRO_FEATURES-derived at
# all, has to be added explicitly.
#
# Without it: SDL_CreateWindow fails at runtime with "Could not
# initialize OpenGL / GLES library" even though the build succeeds
# fine (opengl/gles2 still resolve at link time via virtual/egl,
# provided by rockchip-libmali) - found running our SDL2 app on real
# hardware. DEPENDS (libdrm, virtual/libgbm) are already satisfied:
# rockchip-libmali (MALI_GPU=bifrost-g52 for this SoC family, see
# rk356x.inc) already PROVIDES virtual/libgbm.
PACKAGECONFIG:append:radxa-zero-3e = " kmsdrm"
