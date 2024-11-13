from "%globalsDarg/darg_library.nut" import *
let { btnBgColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkRingGradientLazy } = require("%rGui/style/gradients.nut")

let gradient = mkRingGradientLazy(50, 10, 20)

let damagePanelBacklight = @(stateFlags, size) @() !stateFlags || !(stateFlags.value & S_ACTIVE)
  ? { watch = stateFlags }
  : {
      watch = stateFlags
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      size
      rendObj = ROBJ_IMAGE
      image = gradient()
      color = btnBgColor.ready
    }

return damagePanelBacklight
