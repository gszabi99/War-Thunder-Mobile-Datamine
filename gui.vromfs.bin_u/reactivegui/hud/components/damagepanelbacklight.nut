from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/hudTouchButtonStyle.nut" import btnBgStyle
from "%rGui/style/gradients.nut" import mkRingGradientLazy


let gradient = mkRingGradientLazy(50, 10, 20)

let damagePanelBacklight = @(stateFlags, size) @() !stateFlags || !(stateFlags.get() & S_ACTIVE)
  ? { watch = stateFlags }
  : {
      watch = [stateFlags, btnBgStyle]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      size
      rendObj = ROBJ_IMAGE
      image = gradient()
      color = btnBgStyle.get().ready
    }

return damagePanelBacklight
