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

# wayland is compiled in too by default (DISTRO_FEATURES has it), even
# though this board never has a compositor - and it's actively
# harmful here, not just unused: SDL2 still probes the wayland backend
# internally regardless of SDL_VIDEODRIVER, and our app segfaulted on
# real hardware inside Wayland_VideoQuit -> Wayland_VideoCleanup with
# a NULL SDL_VideoData* (confirmed via gdb against a core dump pulled
# from the board over SSH - the wayland bootstrap's own create/init
# never got the chance to populate its private data before something
# tore it down). Remove it outright rather than relying on
# SDL_VIDEODRIVER=kmsdrm to steer around a driver that shouldn't be
# compiled in on this board at all.
PACKAGECONFIG:remove:radxa-zero-3e = " wayland"

# SDL2 auto-starts a background HIDAPI enumeration thread regardless
# of SDL_Init() flags (our app only requests SDL_INIT_VIDEO |
# SDL_INIT_TIMER | SDL_INIT_EVENTS - no joystick/haptic at all) -
# whatever USB HID device it finds (this board has a UVC webcam
# attached, which exposes a HID interface) gets probed as a
# game controller. Our app segfaulted on real hardware in
# SDL_SYS_ToFFEffect (haptic/force-feedback code) with a NULL dest,
# confirmed via gdb against a core dump - a second, different crash
# than the wayland one above, found on the same board after that fix
# landed. The app has no use for any of this, so disable it outright
# rather than chase whatever HID device trips it up next.
EXTRA_OECMAKE:append:radxa-zero-3e = " -DSDL_JOYSTICK=OFF -DSDL_HAPTIC=OFF -DSDL_HIDAPI=OFF"
