from "%globalsDarg/darg_library.nut" import *
let { goodTextColor, premiumTextColor } = require("%rGui/style/stdColors.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation, getUnitClassFontIcon, getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkOfferWrap, txt, textArea, mkBgImg, mkFitCenterImg, mkPricePlate,
  mkGoodsCommonParts, mkOfferCommonParts, mkOfferTexts
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { discountTagBig } = require("%rGui/components/discountTag.nut")

let priceBgGrad = mkColoredGradientY(0xFFD2A51E, 0xFF91620F, 12)
let fonticonPreview = "⌡"

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

let function getUnit(goods) {
  let unit = serverConfigs.value?.allUnits[goods?.unitUpgrades[0]]
  if (unit != null)
    return unit.__merge({ isUpgraded = true })
  return serverConfigs.value?.allUnits?[goods.units?[0]]
}

let function isUnitOrUnitUpgradePurchased(myUnitsValue, unit) {
  let { name = "", isUpgraded = false } = unit
  let ownUnit = myUnitsValue?[name]
  return ownUnit != null && (!isUpgraded || ownUnit.isUpgraded)
}

let getLocNameUnit = function(goods) {
  let unit = getUnit(goods)
  return unit != null ? getPlatoonOrUnitName(unit, loc) : goods.id
}

let mkUnitImg = @(img) {
  size = flex()
  margin = [ hdpx(40), hdpx(40), 0, 0 ]
  rendObj = ROBJ_IMAGE
  image = Picture(img)
  keepAspect = KEEP_ASPECT_FIT
  imageHalign = ALIGN_LEFT
  imageValign = ALIGN_BOTTOM
}

let function mkSquareIconBtn(text, onClick, ovr) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [ hdpx(70), hdpx(70) ]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    onElemState = @(v) stateFlags(v)
    sound = { click  = "click" }
    transform = {
      scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.85, 0.85] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    children = [
      {
        size = flex()
        rendObj = ROBJ_SOLID
        color = 0x80000000
      }
      txt({ text }.__update(fontBig))
    ]
  }.__merge(ovr)
}

let eliteSize = hdpxi(50)
let eliteMark = {
  size = [eliteSize, eliteSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#icon_premium.avif:{eliteSize}:{eliteSize}")
}

let function mkUnitTexts(goods, unit) {
  let { isUpgraded = false, isPremium = false } = unit
  let isElite = isUpgraded || isPremium
  let color = isElite ? premiumTextColor : 0xFFFFFFFF
  return {
    size = flex()
    flow = FLOW_VERTICAL
    padding = [ hdpx(53), hdpx(34), 0, hdpx(34) ]
    children = [
      {
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(10)
        children = [
          isElite ? eliteMark : null
          textArea({
            size = SIZE_TO_CONTENT
            maxWidth = flex()
            text = getLocNameUnit(goods)
            font = Fonts.wtfont
            fontSize = hdpx(42)
            fontFxFactor = hdpx(32)
            halign = ALIGN_RIGHT
            color
          })
        ]
      }
      txt({
        hplace = ALIGN_RIGHT
        text = getUnitClassFontIcon(unit)
        color
      }.__update(fontMedium))
    ]
  }
}

let mkPurchasedText = @(unit) @() !isUnitOrUnitUpgradePurchased(myUnits.value, unit)
  ? { watch = myUnits }
  : textArea({
      watch = myUnits
      halign = ALIGN_CENTER
      vplace = ALIGN_CENTER
      pos = [0, hdpx(30) ]
      text = loc("mainmenu/itemReceived")
      color = goodTextColor
      transform = { rotate = -20 }
    }.__update(fontBig))

let function mkGoodsUnit(goods, onClick, state, animParams) {
  let unit = getUnit(goods)
  let p = getUnitPresentation(unit)
  return mkGoodsWrap(onClick,
    unit == null ? [] : @(sf) [
      mkBgImg($"!ui/unitskin#flag_{unit.country}.avif")
      mkBgImg($"!ui/unitskin#bg_ground_{unit.unitType}.avif")
      sf & S_HOVER ? bgHiglight : null
      mkUnitImg(p.image)
      mkUnitTexts(goods, unit)
      mkPurchasedText(unit)
      mkSquareIconBtn(fonticonPreview, @() openGoodsPreview(goods.id),
        { vplace = ALIGN_BOTTOM, margin = hdpx(20) })
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams))
}

let function mkOfferUnit(goods, onClick, state, needPrice) {
  let unit = getUnit(goods)
  let { endTime = 0, discountInPercent = 0 } = goods
  let p = getUnitPresentation(unit)
  let bgImg = unit.unitType == "tank"
    ? "ui/gameuiskin#offer_bg_yellow.avif"
    : "ui/gameuiskin#offer_bg_blue.avif"
  return mkOfferWrap(onClick,
    unit == null ? [] : @(sf) [
      mkBgImg(bgImg)
      sf & S_HOVER ? bgHiglight : null
      mkFitCenterImg(p.image)
      mkOfferTexts(loc($"offer/unit/{unit.unitType}s"), endTime)
      discountTagBig(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)),
    needPrice ? mkPricePlate(goods, priceBgGrad, state, null, false) : null)
}

return {
  getLocNameUnit
  mkGoodsUnit
  mkOfferUnit
}
