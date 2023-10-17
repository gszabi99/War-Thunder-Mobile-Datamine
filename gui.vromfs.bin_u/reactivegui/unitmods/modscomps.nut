from "%globalsDarg/darg_library.nut" import *

let lockIconSize = hdpxi(85)
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
      children = {
        rendObj = ROBJ_IMAGE
        size = [lockIconSize, lockIconSize]
        image = Picture($"ui/gameuiskin#lock_unit.svg:{lockIconSize}:{lockIconSize}:P")
        keepAspect = KEEP_ASPECT_FIT
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = {
          rendObj = ROBJ_TEXT
          text = reqLevel
          pos = [hdpx(1), hdpx(13)]
        }.__update(fontVeryTiny)
      }
    }

let mkNotPurchasedShade = @(isPurchased) @() isPurchased.value ? { watch = isPurchased }
  : bgShade.__merge({ watch = isPurchased })

return {
  mkLevelLock
  mkNotPurchasedShade
  bgShade
}
