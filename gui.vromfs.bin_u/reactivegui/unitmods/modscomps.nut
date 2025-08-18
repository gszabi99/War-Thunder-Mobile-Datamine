from "%globalsDarg/darg_library.nut" import *

let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { getModCurrency, getModCost } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { contentMargin } = require("%rGui/unitMods/unitModsConst.nut")
let { CS_COMMON } = require("%rGui/components/currencyStyles.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")

let defLockIconSize = hdpxi(85)
let bgShadeColor = 0x80000000
let defImage = "ui/gameuiskin#upgrades_tools_icon.avif:0:P"

let bgShade = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = bgShadeColor
}

let mkLevelLockBase = @(reqLevel, iconSize, textOvr = {}) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(30)
  children = {
    rendObj = ROBJ_IMAGE
    size = [iconSize, iconSize]
    image = Picture($"ui/gameuiskin#lock_unit.svg:{iconSize}:{iconSize}:P")
    keepAspect = KEEP_ASPECT_FIT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_TEXT
      text = reqLevel
    }.__update(textOvr)
  }
}

let mkLevelLock = @(reqLevel)
  mkLevelLockBase(reqLevel, defLockIconSize, { pos = [hdpx(1), hdpx(13)] }.__update(fontVeryTiny))
let mkLevelLockSmall = @(reqLevel)
  mkLevelLockBase(reqLevel, hdpxi(60), { pos = [hdpx(1), hdpx(9)] }.__update(fontVeryVeryTiny))

let mkNotPurchasedShade = @(isPurchased) @() isPurchased.value ? { watch = isPurchased }
  : bgShade.__merge({ watch = isPurchased })

let mkModImage = @(mod) mod?.name == null ? null : {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin/{mod.name}.avif:0:P")
  fallbackImage = Picture(defImage)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_LEFT
  imageValign = ALIGN_BOTTOM
}

let mkModCost = @(isPurchased, isLocked, mod, unitAllModsCost, currencyStyle = CS_COMMON) @() {
  watch = [isPurchased, isLocked, mod, unitAllModsCost]
  margin = contentMargin
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  children = isPurchased.get() || isLocked.get() || mod.get() == null ? null
    : mkCurrencyComp(getModCost(mod.get(), unitAllModsCost.get()), getModCurrency(mod.get()), currencyStyle)
}

let mkUnseenModIndicator = @(isUnseen) @() {
  watch = isUnseen
  margin = contentMargin
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  children = isUnseen.get() ? priorityUnseenMark : null
}

return {
  mkLevelLock
  mkLevelLockSmall
  mkNotPurchasedShade
  bgShade
  mkModImage
  mkModCost
  mkUnseenModIndicator
}
