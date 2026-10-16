# OV5647 camera via the RK3566 ISP - enablement plan

**Status: confirmed working on real hardware.** The devicetree patch
boots cleanly and produces real, correctly-exposed frames through the
full sensor -> CSI2 -> ISP v2.1 pipeline - see "Real hardware test
results" below for exactly what was checked and what came back.

## Goal, scoped deliberately

Get the OV5647 sensor producing frames through the kernel/devicetree path,
verified with the simplest possible test - **no ISP 3A/color processing
yet**. Decided explicitly (via AskUserQuestion) after finding a real gap:
Rockchip's own vendor tuning files for this chip's ISP version don't include
an OV5647 profile. Chasing a good color image now would mean either fighting
a known-wrong borrowed tuning file or pulling in an entire second camera
stack (libcamera) that isn't in this project at all - neither is "easy and
lightweight." Proving the sensor+kernel+devicetree path works first is the
right-sized first step; ISP/AIQ tuning is a deliberately separate, later
decision.

## Confirmed facts (not guessed)

- **RK3566 uses ISP v2.1** - confirmed directly in
  `conf/machine/include/rk356x.inc` (`RK_ISP_VERSION := "2.1"`,
  `RK_SOC_FAMILY := "rk3568"`). This rules out the `rockchip-rkisp` recipe
  already in this layer (`recipes-multimedia/rockchip-rkisp/rockchip-rkisp.bb`,
  `camera_engine_rkisp`) - that one targets the **older ISP v1** hardware
  generation (RK3399-class chips), a different driver/userspace stack
  entirely, not applicable to this board.
- **`rockchip-rkaiq`** (`recipes-multimedia/rockchip-rkaiq/rockchip-rkaiq.bb`,
  `camera_engine_rkaiq`, branch `rkaiq-2024_04_08`) is the stack that
  actually matches this chip's ISP version - confirmed via its own
  `IQFILES_DIR` computation (`isp${RK_ISP_VERSION}` -> `isp21` for this
  board) - but it is **not currently in `IMAGE_INSTALL` anywhere** in this
  project, and its own `do_install` explicitly strips the easy
  interactive test tools (`rm -rf ... *demo ... rkaiq_tool_server dumpcam`),
  keeping only the bare `rkaiq_3A_server` daemon. Not needed for this
  phase's raw-capture goal regardless.
- **No OV5647 tuning file ships in `iqfiles/isp21/`** in that upstream
  source - confirmed via multiple sources describing OV5647/IMX219 support
  in Rockchip's own vendor camera engine as explicitly limited. (Separately,
  there's unrelated upstream work adding real OV5647 tuning to **libcamera**'s
  own `rkisp1` IPA - a completely different, open-source camera stack not
  present in this project; out of scope for now per the decision above.)
- **The OV5647 kernel driver already exists** in this exact pinned kernel
  fork (`github.com/JeffyCN/mirrors`, `kernel-6.1-2024_04_14` branch,
  SRCREV `ea9e2a9344bfe7f1130dee8100173b6cb95445d2` - same kernel this
  project already builds, confirmed via
  `meta-rockchip/recipes-kernel/linux/linux-rockchip_6.1.bb`) at
  `drivers/media/i2c/ov5647.c`. Confirmed (read directly, not assumed):
  registers `compatible = "ovti,ov5647"` (standard mainline binding, matches
  `Documentation/devicetree/bindings/media/i2c/ovti,ov5647.yaml`), requires
  a devicetree clock reference running at **exactly 25 MHz** (hard error if
  not), an optional `"pwdn"` GPIO (requested high/deasserted-low semantics),
  and a standard MIPI CSI-2 endpoint description.
- **Mainline's own `VIDEO_ROCKCHIP_ISP1` Kconfig** (`drivers/media/platform/
  rockchip/rkisp1/Kconfig`, same repo) explicitly scopes itself to "the ISP
  module present in RK3399 SoCs" - confirms (again) this is the wrong driver
  for this board. The vendor-BSP ISP driver that actually matches RK3568/
  ISP v2.1 is a separate, larger driver elsewhere in this same kernel tree
  (typical of Rockchip vendor kernels carrying both a small mainline-derived
  `rkisp1` driver and their own much larger versioned vendor ISP driver side
  by side) - confirmed below (`VIDEO_ROCKCHIP_ISP`, under
  `drivers/media/platform/rockchip/isp/`).

## Open items - all resolved

Correction made along the way: the kernel source to actually check was
**not** `JeffyCN/mirrors` (this recipe's own default) - `radxa-zero-3e`
overrides it entirely to `radxa/kernel.git`, branch `linux-6.1-stan-
rkr5.1`, SRCREV `f87fca6cefcb6229c7f81399dd351cf658940bfa` (see the
bbappend's own `SRC_URI:radxa-zero-3e`). Re-did this research against
that real source (fetched the pinned commit directly, not guessed):

1. **Kconfig**: `CONFIG_VIDEO_OV5647=y`, `CONFIG_VIDEO_ROCKCHIP_CIF=y`,
   `CONFIG_VIDEO_ROCKCHIP_ISP=y` are **already set** in this fork's own
   `arch/arm64/configs/rockchip_linux_defconfig` - confirmed by reading it
   directly. `VIDEO_ROCKCHIP_ISP_VERSION_V21` ("isp21 for rk3566 and
   rk3568", confirmed via that Kconfig's own help text) isn't itself listed
   but has `default y depends on CPU_RK3568`, and `CONFIG_CPU_RK3568=y` is
   set - resolves to on automatically. **No kernel config fragment needed
   at all** - this turned out to be a devicetree-only change.
2. **Board wiring**: found and verified a real, working reference instead
   of inventing one - Armbian's own `linux-rockchip` fork (same kernel
   lineage) ships `arch/arm64/boot/dts/rockchip/overlay/
   radxa-zero3-rpi-camera-v1.3.dts` for this exact board+sensor pairing.
   i2c2 @ 0x36, pwdn on GPIO3_PC6 (active-low), dedicated 25MHz
   `fixed-clock`, full-mode `csi2_dphy0` routed directly to `rkisp_vir0`.
   Confirmed every referenced label (`i2c2`, `gpio3`, `i2c2m1_xfer`,
   `csi2_dphy_hw`, `csi2_dphy0`, `rkisp_vir0`, `rkisp`, `rkisp_mmu`,
   `rkcif_mmu`, `rkcif`) actually exists in this board's own real include
   chain (`rk3566-radxa-zero3.dtsi` -> `rk3566.dtsi` -> `rk356x.dtsi` ->
   `rk3568-pinctrl.dtsi`), and that GPIO3_PC6/i2c2 aren't already used by
   anything else on this board, by reading those files directly - not
   assumed from the overlay alone.
3. Patch generated mechanically (applied the change to a real copy of the
   file, then `diff -u`), not hand-written - caught and fixed a real
   hand-counted hunk-header bug in an earlier draft this way. Dry-run
   verified against the real pinned source before being written into the
   recipe.

## What was actually implemented

1. **`meta-rockchip/recipes-kernel/linux/linux-rockchip_6.1/
   0001-arm64-dts-rockchip-radxa-zero-3e-enable-OV5647-came.patch`** -
   patches `rk3566-radxa-zero3.dtsi` (the shared "zero3" family base this
   board's own `.dts` includes), wired into `linux-rockchip_6.1.bbappend`'s
   `SRC_URI:radxa-zero-3e`. No `.cfg` fragment - not needed, see above.
2. **`meta-toletus/conf/layer.conf`** -
   `IMAGE_INSTALL:append:radxa-zero-3e = " v4l-utils"` for `media-ctl`/
   `v4l2-ctl`. Deliberately **not** adding `rockchip-rkaiq` yet - out of
   scope per the decision above.

## Real hardware test results

Resolved the one open question the original research pass flagged: the
devicetree path terminates at `rkisp_vir0` (ISP input), so there is no
raw-sensor-subdevice bypass node - the practical capture target is the
ISP's own `rkisp_mainpath` output node, not a direct `/dev/v4l-subdevN`
tap. Confirmed directly on boot, not guessed:

```
dmesg | grep -iE 'ov5647|rkisp|rkcif|csi2'
# ov5647 2-0036: OmniVision OV5647 camera driver probed
# rockchip-csi2-dphy csi2-dphy0: dphy0 matches m00_b_ov5647 2-0036:bus type 5
# rkisp-vir0: Async subdev notifier completed
# rkisp rkisp-vir0: clear unready subdev num: 0

media-ctl -p
# full graph present and ENABLED end to end: m00_b_ov5647 2-0036 ->
# rockchip-csi2-dphy0 -> rkisp-csi-subdev -> rkisp-isp-subdev ->
# rkisp_mainpath/rkisp_selfpath, sensor reporting its real native
# format (SGBRG10_1X10/2592x1944 - OV5647's actual spec, not a stub)

v4l2-ctl --list-devices
# rkisp_mainpath (platform:rkisp-vir0): /dev/video0 ... /dev/media0
```

Capture test:

```bash
v4l2-ctl -d /dev/video0 -v width=640,height=480,pixelformat=NV12 \
  --stream-mmap --stream-count=5 --stream-to=/tmp/ov5647-test.nv12
```

First attempt (no light reaching the lens) came back byte-exact in size
but essentially flat (Y-plane values 3-5 only, ~3 distinct values) and
**did not change at all** even after maxing the sensor's own `exposure`
(1000->1964) and `analogue_gain` (32->1023, a 32x increase) via
`v4l2-ctl -d /dev/v4l-subdev3 -c exposure=...,analogue_gain=...` - real
sensor noise under that much gain should visibly widen even in total
darkness, so this pointed at "no real optical signal reaching the
sensor" rather than an ISP-processing gap. Verified the pipeline itself
was still fully live during this (not just guessed): `pwdn` GPIO read
back `out hi, ACTIVE LOW` (= logically deasserted = powered up) and
`clk_cam_25m`'s `clk_enable_count`/`clk_prepare_count` both read `1`
while actively streaming (checked mid-stream with a `--stream-count=60`
background capture, not after it finished) - confirmed via
`/sys/kernel/debug/gpio` and `/sys/kernel/debug/clk/clk_cam_25m/`.
Frame delivery was a steady, real 15.63 fps the whole time.

Pointing the lens at an actual light source and recapturing confirmed
it: frame 0 (transient, still settling right after `STREAMON`) then
frames 1-4 stable at **mean ~142, 230 distinct byte values across the
full 0-255 range** - genuine image structure, not noise, not a stuck
pipeline. Rendered the luma plane directly (`PIL.Image.frombytes('L',
(640,480), ...)`, no demosaic needed for a grayscale check) and got a
real photographed image (a blurred light source with a visible
glow/flare pattern - soft because there's no lens-shading/sharpening
without ISP 3A running, but unambiguously a real scene, not garbage).

This confirms the sensor+kernel+devicetree+ISP-binding path end to end,
exactly what this phase set out to prove. No raw/pre-ISP capture node
was reachable for an even-more-bypassed test (`rkisp_rawwr0`/
`/dev/video2` accepts `STREAMON` but never delivers a buffer standalone
- it appears to need the main ISP pipeline driving it concurrently, not
a priority to chase further here since `/dev/video0` already gives a
conclusive result). Color accuracy, sharpness and auto-exposure/white-
balance are still the deliberately deferred next-phase work (needs
`rockchip-rkaiq`'s 3A daemon, which has no OV5647 tuning file upstream -
the known gap from the top of this doc).

## Staged rollout

1. ~~Resolve the three open items above against the real, checked-out
   kernel source~~ - done, see "Open items - all resolved" above.
2. ~~Build with the dts patch, boot, confirm `media-ctl -p`/
   `v4l2-ctl --list-devices` shows the sensor and a corresponding video
   node~~ - done, see "Real hardware test results" above.
3. ~~Capture frames; confirm size/content is real, not garbage or a
   stuck pipeline~~ - done, see above (byte-exact sizing throughout,
   real 230-distinct-value image once light was present).
4. Next, separate piece of work: the AIQ/tuning-file decision (adapt a
   borrowed tuning file vs. investigate libcamera), informed by whatever
   image-quality bar actually matters for the eventual use case.
