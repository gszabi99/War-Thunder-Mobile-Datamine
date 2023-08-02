from "%globalsDarg/darg_library.nut" import *

let lockIconSize = hdpxi(44)
let bgShadeColor = 0x80000000

let bgShade = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = bgShadeColor
}

let mkLevelLock = @(isLocked, reqLevel) @() !isLocked.value ? { watch = isLocked }
  : {
      watch = isLocked
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(30)
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = [lockIconSize, lockIconSize]
          image = Picture($"ui/gameuiskin#lock_icon.svg:{lockIconSize}:{lockIconSize}:P")
        }
        {
          rendObj = ROBJ_TEXT
          text = "".concat(loc("multiplayer/level"), "  ", reqLevel)
        }.__update(fontSmall)
      ]
    }

let mkNotPurchasedShade = @(isPurchased) @() isPurchased.value ? { watch = isPurchased }
  : bgShade.__merge({ watch = isPurchased })

return {
  mkLevelLock
  mkNotPurchasedShade
  bgShade
}
