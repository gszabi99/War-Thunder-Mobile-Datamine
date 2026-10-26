from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/hudTouchButtonStyle.nut" import btnBgStyle
from "%rGui/style/gradients.nut" import mkRingGradientLazy


let gradient = mkRingGradientLazy(50, 10, 20)

function damagePanelBacklight(stateFlags, size) {
  let glowImage = gradient()
  return @() !stateFlags || !(stateFlags.get() & S_ACTIVE)
    ? { watch = stateFlags }
    : {
        watch = [stateFlags, btnBgStyle]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        size
        rendObj = ROBJ_IMAGE
        image = glowImage
        color = btnBgStyle.get().ready
      }
}

return damagePanelBacklight
