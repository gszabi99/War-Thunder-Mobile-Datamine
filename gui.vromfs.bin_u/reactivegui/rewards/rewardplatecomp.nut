from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { decimalFormat, shortTextFromNum } = require("%rGui/textFormatByLang.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getUnitPresentation, getUnitClassFontIcon } = require("%appGlobals/unitPresentation.nut")
let { mkUnitBg, mkUnitImage, mkIcon, mkPlateText } = require("%rGui/unit/components/unitPlateComp.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { getLootboxImage } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")

// PREDEFINED STYLES ///////////////////////////////////////////////////////////

let fontLabel = fontTiny
let fontLabelSmaller = fontVeryTiny
let labelHeight = round(fontLabel.fontSize * 1.3).tointeger()
let labelInlineIcoSize = round(fontLabel.fontSize * 0.92).tointeger()

let mkRewardStyle = @(boxSize) {
  boxSize
  boxGap = round(boxSize * 0.26).tointeger()
  iconShiftY = round((labelHeight * -0.5) + (boxSize * 0.04)).tointeger()
  labelCurrencyNeedCompact = boxSize < fontLabel.fontSize * 5.5
}

let REWARD_SIZE_SMALL = hdpxi(114)
let REWARD_SIZE_MEDIUM = hdpxi(160)
let REWARD_STYLE_SMALL = mkRewardStyle(REWARD_SIZE_SMALL)
let REWARD_STYLE_MEDIUM = mkRewardStyle(REWARD_SIZE_MEDIUM)

// SHARED PARTS ///////////////////////////////////////////////////////////////

let function getRewardPlateSize(r, rStyle) {
  let { slots } = r
  let { boxSize, boxGap } = rStyle
  return [ (r.slots * boxSize) + ((slots - 1) * boxGap), boxSize ]
}

let iconBase = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
}

let mkCommonLabelText = @(text, rStyle) {
  maxWidth = rStyle.boxSize
  rendObj = ROBJ_TEXT
  text
}.__update(fontLabel)

let mkCommonLabelTextMarquee = @(text, rStyle) {
  maxWidth = rStyle.boxSize
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  text
}.__update(fontLabelSmaller)

let mkRewardLabel = @(children, needPadding = true) {
  size = [flex(), labelHeight]
  padding = needPadding ? [0, hdpx(5)] : null
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  clipChildren = true
  rendObj = ROBJ_SOLID
  color = 0x80000000
  flow = FLOW_HORIZONTAL
  children
}

let mkRewardPlateCountText = @(r, rStyle) mkRewardLabel(mkCommonLabelText(decimalFormat(r.count), rStyle))

// CURRENCY ///////////////////////////////////////////////////////////////////

let currencyImgPaths = {
  gold = "ui/gameuiskin#shop_eagles_02.avif"
  wp = "ui/gameuiskin#shop_lions_02.avif"
}

let function mkRewardPlateCurrencyImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r, rStyle)
  let imgPath = currencyImgPaths[r.id]
  let w = round(size[1] * 1.1)
  let h = round(w / 469 * 291)
  return {
    size
    clipChildren = true
    children = iconBase.__merge({
      size = [w, h]
      pos = [w * 0.12, iconShiftY + (h * -0.07)]
      image = Picture($"{imgPath}:{w}:{h}:P")
    })
  }
}

let function mkRewardPlateCurrencyTexts(r, rStyle) {
  let { labelCurrencyNeedCompact } = rStyle
  let countText = labelCurrencyNeedCompact ? shortTextFromNum(r.count) : decimalFormat(r.count)
  let icoMargin = labelInlineIcoSize * (labelCurrencyNeedCompact ? 0.1 : 0.3)
  return mkRewardLabel([
    mkCurrencyImage(r.id, labelInlineIcoSize, { margin = [ 0, icoMargin, 0, 0 ] })
    mkCommonLabelText(countText, rStyle)
  ])
}

// PREMIUM ////////////////////////////////////////////////////////////////////

let function mkRewardPlatePremiumImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r, rStyle)
  let w = round(size[1] * 0.77)
  let h = round(w / 286 * 197)
  return {
    size
    children = iconBase.__merge({
      size = [w, h]
      pos = [ 0, iconShiftY ]
      image = Picture($"ui/gameuiskin#premium_active_big.avif:{w}:{h}:P")
    })
  }
}

let mkRewardPlatePremiumTexts = @(r, rStyle)
  mkRewardLabel(mkCommonLabelText("".concat(decimalFormat(r.count), loc("measureUnits/days")), rStyle))

// DECORATOR //////////////////////////////////////////////////////////////////

let mkDecoratorIconAvatar = @(decoratorId, _rStyle, size) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"{getAvatarImage(decoratorId)}:O:P")
}

let decoratorFontIconBase = {
  size = [flex(), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
}.__merge(fontLabel)

let mkDecoratorIconTitle = @(decoratorId, rStyle, _size) decoratorFontIconBase.__merge({
  pos = [ 0, rStyle.iconShiftY ]
  behavior = Behaviors.Marquee
  text = loc($"title/{decoratorId}")
})

let mkDecoratorIconNickFrame = @(decoratorId, rStyle, size) decoratorFontIconBase.__merge({
  pos = [ 0, rStyle.iconShiftY ]
  text = frameNick("", decoratorId)
  fontSize = round(size[0] / 2.75)
})

let decoratorIconContentCtors = {
  avatar    = mkDecoratorIconAvatar
  title     = mkDecoratorIconTitle
  nickFrame = mkDecoratorIconNickFrame
}

let function mkRewardPlateDecoratorImage(r, rStyle) {
  let { id } = r
  let size = getRewardPlateSize(r, rStyle)
  let decoratorType = Computed(@() (allDecorators.value?[id].dType))
  let comp = { watch = decoratorType }
  return @() decoratorType.value == null ? comp : comp.__update({
    size
    children = decoratorIconContentCtors?[decoratorType.value](id, rStyle, size)
  })
}

let function mkRewardPlateDecoratorTexts(r, rStyle) {
  let { id } = r
  let decoratorType = Computed(@() (allDecorators.value?[id].dType))
  let comp = { watch = decoratorType }
  return @() decoratorType.value == null ? comp : comp.__update(mkRewardLabel(
    mkCommonLabelTextMarquee(loc($"decorator/{allDecorators.value?[id].dType}"), rStyle), false))
}

// ITEM ///////////////////////////////////////////////////////////////////////

let function mkRewardPlateItemImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r, rStyle)
  let iconSize = round(size[1] * 0.55)
  return {
    size
    clipChildren = true
    children = mkCurrencyImage(r.id, iconSize, { hplace = ALIGN_CENTER, pos = [ 0, iconShiftY ] })
  }
}

// LOOTBOX ////////////////////////////////////////////////////////////////////

let function mkRewardPlateLootboxImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r, rStyle)
  let iconSize = round(size[1] * 0.67)
  return {
    size
    children = iconBase.__merge({
      size = [iconSize, iconSize]
      pos = [ 0, iconShiftY ]
      image = getLootboxImage(r.id, iconSize)
    })
  }
}

// UNIT ///////////////////////////////////////////////////////////////////////

let function mkRewardPlateUnitImageImpl(r, rStyle, isUpgraded) {
  let unit = Computed(@() serverConfigs.value?.allUnits?[r.id].__merge({ isUpgraded }))
  let comp = { watch = unit }
  return @() unit.value == null ? comp : comp.__update({
    size = getRewardPlateSize(r, rStyle)
    children = [
      mkUnitBg(unit.value)
      mkUnitImage(unit.value)
    ]
  })
}

let mkRewardPlateUnitImage = @(r, rStyle) mkRewardPlateUnitImageImpl(r, rStyle, false)
let mkRewardPlateUnitUpgradeImage = @(r, rStyle) mkRewardPlateUnitImageImpl(r, rStyle, true)

let function mkUnitTextsImpl(r, rStyle, isUpgraded) {
  let unit = Computed(@() serverConfigs.value?.allUnits?[r.id].__merge({ isUpgraded }))
  let unitLocName = loc(getUnitPresentation(unit.value).locId)
  let size = getRewardPlateSize(r, rStyle)
  let comp = { watch = unit }
  return @() unit.value == null ? comp : comp.__update({
    size
    padding = [0, hdpx(5)]
    clipChildren = true
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        pos = [0, hdpx(3)]
        flow = FLOW_VERTICAL
        halign = ALIGN_RIGHT
        children = [
          {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            gap = hdpx(8)
            children = [
              unit.value.isPremium || unit.value?.isUpgraded
                  ? mkIcon("ui/gameuiskin#icon_premium.svg", [hdpxi(60), hdpxi(30)], { pos = [ 0, hdpx(3) ] })
                : null
              mkPlateText(unitLocName)
            ]
          }
          mkPlateText(getUnitClassFontIcon(unit.value), fontLabel)
        ]
      }
      {
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        children = mkGradRank(unit.value.mRank)
      }
    ]
  })
}

let mkRewardPlateUnitTexts = @(r, rStyle) mkUnitTextsImpl(r, rStyle, false)
let mkRewardPlateUnitUpgradeTexts = @(r, rStyle) mkUnitTextsImpl(r, rStyle, true)

// UNKNOWN ////////////////////////////////////////////////////////////////////

let function mkRewardPlateUnknownImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r, rStyle)
  let iconSize = round(size[1] * 0.6)
  return {
    size
    children = iconBase.__merge({
      size = [iconSize, iconSize]
      pos = [ 0, iconShiftY ]
      image = Picture($"ui/gameuiskin#placeholder.svg:{iconSize}:{iconSize}:P")
    })
  }
}

// LAYER CONSTRUCTORS /////////////////////////////////////////////////////////

let function mkRewardPlateBg(r, rStyle) {
  let size = getRewardPlateSize(r, rStyle)
  return {
    size
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/images/offer_item_slot_bg.avif:{size[0]}:{size[1]}:P")
  }
}

let rewardPlateCtors = {
  unknown = {
    image = mkRewardPlateUnknownImage
    texts = mkRewardPlateCountText
  }
  currency = {
    image = mkRewardPlateCurrencyImage
    texts = mkRewardPlateCurrencyTexts
  }
  premium = {
    image = mkRewardPlatePremiumImage
    texts = mkRewardPlatePremiumTexts
  }
  decorator = {
    image = mkRewardPlateDecoratorImage
    texts = mkRewardPlateDecoratorTexts
  }
  item = {
    image = mkRewardPlateItemImage
    texts = mkRewardPlateCountText
  }
  lootbox = {
    image = mkRewardPlateLootboxImage
    texts = mkRewardPlateCountText
  }
  unitUpgrade = {
    image = mkRewardPlateUnitUpgradeImage
    texts = mkRewardPlateUnitUpgradeTexts
  }
  unit = {
    image = mkRewardPlateUnitImage
    texts = mkRewardPlateUnitTexts
  }
}

let mkRewardPlateImage = @(r, rStyle) (rewardPlateCtors?[r?.rType] ?? rewardPlateCtors.unknown).image(r, rStyle)
let mkRewardPlateTexts = @(r, rStyle) (rewardPlateCtors?[r?.rType] ?? rewardPlateCtors.unknown).texts(r, rStyle)

let mkRewardPlate = @(r, rStyle, ovr = {}) {
  children = [
    mkRewardPlateBg(r, rStyle)
    mkRewardPlateImage(r, rStyle)
    mkRewardPlateTexts(r, rStyle)
  ]
}.__update(ovr)

return {
  REWARD_SIZE_SMALL
  REWARD_STYLE_SMALL
  REWARD_SIZE_MEDIUM
  REWARD_STYLE_MEDIUM

  getRewardPlateSize
  mkRewardPlate
  mkRewardPlateBg
  mkRewardPlateImage
  mkRewardPlateTexts
}
