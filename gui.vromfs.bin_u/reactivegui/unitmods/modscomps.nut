from "%globalsDarg/darg_library.nut" import *

let lockIconSize = hdpxi(85)
let bgShadeColor = 0x80000000
let defImage = "ui/gameuiskin#upgrades_tools_icon.avif:0:P"

let bgShade = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = bgShadeColor
}

let mkLevelLock = @(reqLevel) {
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

let mkModImage = @(mod) mod?.name == null ? null : {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{mod.name}.avif:0:P")
  fallbackImage = Picture(defImage)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_LEFT
  imageValign = ALIGN_BOTTOM
}

return {
  mkLevelLock
  mkNotPurchasedShade
  bgShade
  mkModImage
}
