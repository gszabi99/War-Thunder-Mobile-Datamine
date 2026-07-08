from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideY, gradTexSize, mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { tabsGap } = require("%rGui/components/tabs.nut")
let { getModCost } = require("%rGui/unitMods/unitModsState.nut")
let { modContentMargin, modH, modW, equippedFrameWidth, activeColor, equippedColor,
  blocksLineSize, blocksGap, slotsBlockMargin, contentGamercardGap
} = require("%rGui/unitMods/unitModsConst.nut")
let { catsScrollHandler, carouselScrollHandler } = require("%rGui/unitMods/unitModsScroll.nut")
let { CS_SMALL } = require("%rGui/components/currencyStyles.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let bulletTypeIconSize = hdpxi(80)
let defLockIconSize = hdpxi(85)
let bgShadeColor = 0x80000000
let defImage = "ui/gameuiskin#upgrades_tools_icon.avif:0:P"

let lineGradientVert = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, 0xFFFFFFFF, 0.25))

let bgShade = {
  size = FLEX
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

let mkNotPurchasedShade = @(isPurchased) @() isPurchased.get() ? { watch = isPurchased }
  : bgShade.__merge({ watch = isPurchased })

let mkModImage = @(mod) mod?.name == null ? null : {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin/{mod.name}.avif:0:P")
  fallbackImage = Picture(defImage)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_LEFT
  imageValign = ALIGN_BOTTOM
}

let mkModCost = @(isPurchased, isLocked, mod, unitModCostCfg, currencyStyle = CS_SMALL, ovr = {}) function() {
  let cost = isPurchased.get() || isLocked.get() || mod.get() == null ? null
    : getModCost(mod.get(), unitModCostCfg.get())
  return {
    watch = [isPurchased, isLocked, mod, unitModCostCfg]
    margin = modContentMargin
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    children = cost == null ? null
      : mkCurrencyComp(cost.price, cost.currencyId, currencyStyle)
  }.__update(ovr)
}

let mkUnseenModIndicator = @(isUnseen) @() {
  watch = isUnseen
  margin = modContentMargin
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  children = isUnseen.get() ? priorityUnseenMark : null
}

let mkEquippedFrame = @(isEquipped, isActive) @() !isEquipped.get() ? { watch = isEquipped }
  : {
      watch = [isEquipped, isActive]
      size = [modW, modH]
      rendObj = ROBJ_FRAME
      borderWidth = equippedFrameWidth
      color = isActive.get() ? activeColor : equippedColor
    }

let mkVerticalPannableArea = @(content, width, pageMaskPict) {
  rendObj = ROBJ_MASK
  image = pageMaskPict
  clipChildren = true
  size = [width, FLEX]
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  children = [
    { size = [FLEX, slotsBlockMargin] }
    {
      size = FLEX
      behavior = Behaviors.Pannable
      padding = [0, 0, saBorders[1], 0]
      touchMarginPriority = TOUCH_BACKGROUND
      scrollHandler = catsScrollHandler
      flow = FLOW_VERTICAL
      gap = tabsGap
      children = content
      xmbNode = XmbContainer()
    }
  ]
}

let mkCarouselPannableArea = @(content, height, pageMaskPict) {
  rendObj = ROBJ_MASK
  image = pageMaskPict
  clipChildren = true
  size = [FLEX, height]
  flow = FLOW_HORIZONTAL
  children = [
    { size = [blocksGap, FLEX] }
    {
      size = FLEX
      padding = [0, saBorders[0], 0, 0]
      behavior = Behaviors.Pannable
      touchMarginPriority = TOUCH_BACKGROUND
      scrollHandler = carouselScrollHandler
      halign = ALIGN_RIGHT
      children = content
      xmbNode = XmbContainer({ scrollSpeed = 2.0 })
    }
  ]
}

let verticalGradientLine = @() {
  size = [blocksLineSize, FLEX]
  margin = [contentGamercardGap, 0, 0, 0]
  rendObj = ROBJ_IMAGE
  image = lineGradientVert()
}

let mkBulletTypeIcon = @(iconBulletType, ammoTypeName) {
  size = FLEX_V
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = [0, equippedFrameWidth * 2, 0, 0]
  children = [
    {
      size = [bulletTypeIconSize, bulletTypeIconSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"{iconBulletType}:{bulletTypeIconSize}:{bulletTypeIconSize}:P")
      keepAspect = KEEP_ASPECT_FIT
    }
    {
      rendObj = ROBJ_TEXT
      text = ammoTypeName
    }.__update(fontVeryTinyShaded)
  ]
}

let catsPanelBg = {
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(0x20000000, 0x60000000)
  flow = FLOW_VERTICAL
}

return {
  mkLevelLock
  mkLevelLockSmall
  mkNotPurchasedShade
  bgShade
  mkModImage
  mkModCost
  mkUnseenModIndicator
  mkEquippedFrame
  mkBulletTypeIcon

  mkVerticalPannableArea
  mkCarouselPannableArea

  verticalGradientLine
  catsPanelBg
}
