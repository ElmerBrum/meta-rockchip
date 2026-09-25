# Temporary: build librga's own im2d API demo (rgaImDemo) to validate
# the RGA kernel driver end to end on real hardware, not just check
# that config/devicetree look right. Remove this file once confirmed
# (meson defaults librga_demo to "false" upstream).
EXTRA_OEMESON:append = " -Dlibrga_demo=true"
