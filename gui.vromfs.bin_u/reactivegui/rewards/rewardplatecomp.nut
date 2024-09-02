from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { getCurrencyImage } = require("%appGlobals/config/currencyPresentation.nut")
let { decimalFormat, shortTextFromNum } = require("%rGui/textFormatByLang.nut")
let { fontLabel, labelHeight, REWARD_STYLE_TINY, REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM,
  getRewardPlateSize, progressBarHeight
} = require("rewardStyles.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getUnitLocId, getUnitClassFontIcon } = require("%appGlobals/unitPresentation.nut")
let { mkUnitBg, mkUnitImage, mkPlateText } = require("%rGui/unit/components/unitPlateComp.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")
let { mkLoootboxImage } = require("%appGlobals/config/lootboxPresentation.nut")
let { getFontToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { getStatsImage } = require("%appGlobals/config/rewardStatsPresentation.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { eventSeason } = require("%rGui/event/eventState.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { getBattleModPresentation } = require("%appGlobals/config/battleModPresentation.nut")
let { mkBattleModEventUnitText, mkBattleModRewardUnitImage, mkBattleModCommonText,
  mkBattleModCommonImage } = require("%rGui/rewards/battleModComp.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { NO_DROP_LIMIT } = require("%rGui/rewards/rewardViewInfo.nut")

let textPadding = [0, hdpx(5)]
let fontLabelSmaller = fontVeryTiny
let fontLabelBig = fontSmall
let searchPlateSize = [evenPx(40), evenPx(40)]
let searchIconSize = evenPx(30)
let transparentBlackColor = 0x80000000

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
}.__update(getFontToFitWidth({ rendObj = ROBJ_TEXT, text }.__update(fontLabel),
  rStyle.boxSize - textPadding[1] * 2, [fontLabelSmaller, fontLabel]))

let mkCommonLabelTextMarquee = @(text, rStyle) {
  maxWidth = rStyle.boxSize - textPadding[1] * 2
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  speed = hdpx(30)
  delay = defMarqueeDelay
  text
}.__update(fontLabelSmaller)

let mkRewardLabel = @(children, needPadding = true) {
  size = [flex(), labelHeight]
  padding = needPadding ? textPadding : null
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  clipChildren = true
  rendObj = ROBJ_SOLID
  color = transparentBlackColor
  flow = FLOW_HORIZONTAL
  children
}

let mkRewardSearchPlate = {
  fillColor = transparentBlackColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  size = searchPlateSize
  lineWidth = hdpx(1)
  commands = [
    [VECTOR_ELLIPSE, 50, 50, 50, 50],
  ]
  children = {
    size = [searchIconSize, searchIconSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#btn_search.svg:{searchIconSize}:{searchIconSize}:P")
    color = 0xFFFFFFFF
  }
}

function mkProgressBarText(r, rStyle) {
  let { labelCurrencyNeedCompact } = rStyle
  let countText = "countRange" in r
      ? "".concat(shortTextFromNum(r.count), "-", shortTextFromNum(r.countRange))
    : labelCurrencyNeedCompact
      ? shortTextFromNum(r.count)
    : decimalFormat(r.count)
  return {
    size = [flex(), progressBarHeight]
    children = {
      rendObj = ROBJ_TEXT
      text = countText
      hplace = ALIGN_RIGHT
      vplace = ALIGN_CENTER
      fontFx = FFT_GLOW
      fontFxColor = 0xFF000000
      fontFxFactor = hdpxi(32)
    }.__update(rStyle.textStyle)
  }
}

let mkProgressBarWithForecast = @(count, available, total) @() {
  size = [flex(), progressBarHeight]
  children = {
    size = flex()
    rendObj = ROBJ_BOX
    fillColor = transparentBlackColor
    children = [
      {
        rendObj = ROBJ_BOX
        size = [
          pw(clamp(100 * ((count.tofloat() + available.tofloat()) / total), 0, 100)),
          progressBarHeight
        ]
        fillColor = 0xFF6EFF95
      }
      {
        rendObj = ROBJ_BOX
        size = [pw(clamp(100 * (available.tofloat() / total), 0, 100)), progressBarHeight]
        fillColor = 0xFF3384C4
      }
    ]
  }
}

let mkProgressBar = @(available, total) @() {
  size = [flex(), progressBarHeight]
  children = {
    size = flex()
    rendObj = ROBJ_BOX
    fillColor = transparentBlackColor
    children = {
      rendObj = ROBJ_BOX
      size = [pw(clamp(100 * (available.tofloat() / total), 0, 100)), progressBarHeight]
      fillColor = 0xFF3384C4
    }
  }
}

let mkProgressLabel = @(available, total, rStyle = {}) {
  size = [flex(), labelHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_RIGHT
    padding = [0, hdpx(5), 0 , 0]
    children = [
      {
        size = [pw(100), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXT
        text = "/".concat(available, total)
        halign = ALIGN_CENTER
        vplace = ALIGN_CENTER
        fontFx = FFT_GLOW
        fontFxColor = 0xFF000000
        fontFxFactor = hdpxi(24)
      }.__update(rStyle.textStyle)
    ]
  }
}

let mkRewardPlateCountText = @(r, rStyle)
  mkRewardLabel(mkCommonLabelText(
    "countRange" in r
        ? "".concat(decimalFormat(r.count), "-", decimalFormat(r.countRange))
      : decimalFormat(r.count),
    rStyle))


let mkRewardFixedIcon = @(rStyle) {
  size = [rStyle.markSize, rStyle.markSize]
  pos = [hdpx(8), hdpx(4)]
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"ui/gameuiskin#events_chest_icon.svg:{rStyle.markSize}:{rStyle.markSize}:P")
}

let mkRewardDisabledBkg = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = transparentBlackColor
}

function mkRewardReceivedMark(rStyle, ovr = {}) {
  let iconSize = 2 * (rStyle.boxSize * 0.3 + 0.5).tointeger()
  return {
    size = flex()
    rendObj = ROBJ_SOLID
    color = transparentBlackColor
    children = {
      size = [iconSize, iconSize]
      pos = [hdpx(10), -hdpx(10)]
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      image = Picture($"ui/gameuiskin#daily_mark_claimed.avif:{iconSize}:{iconSize}:P")
      keepAspect = true
      color = 0xFFFFFFFF
    }
  }.__update(ovr)
}

let mkReceivedCounter = @(received, total) {
  margin = [hdpx(4), hdpx(8)]
  halign = ALIGN_LEFT
  valign = ALIGN_TOP
  rendObj = ROBJ_TEXT
  text = $"{received}/{total}"
}.__update(fontVeryTinyShaded)

function mkUnitNameText(unitNameLoc, size, rStyle) {
  let textStyle = rStyle.textStyle
  let maxTextWidth = size[0] - 2 * textPadding[1] - rStyle.markSize
  local nameText = mkPlateText(unitNameLoc, textStyle)
    if (calc_comp_size(nameText)[0] > maxTextWidth)
      nameText = mkPlateText(unitNameLoc, fontVeryTiny)
        .__update({ behavior = Behaviors.Marquee, maxWidth = maxTextWidth, speed = hdpx(30), delay = defMarqueeDelay })
  return nameText
}

// CURRENCY ///////////////////////////////////////////////////////////////////

function mkGoldOrWpIcon(size, iconShiftY, imgName) {
  let w = round(size[1] * 1.1).tointeger()
  let h = round(w / 469.0 * 291).tointeger()
  return {
    size = [w, h]
    pos = [w * 0.12, iconShiftY + (h * -0.07)]
    image = Picture($"ui/gameuiskin#{imgName}:{w}:{h}:P")
  }.__update(iconBase)
}

function mkOtherCurrencyIcon(size, iconShiftY, imgName, scale, aspectRatio = 1.0) {
  let w = round(size[1] * scale).tointeger()
  let h = round(w * 1.0 / aspectRatio).tointeger()
  return {
    size = [w, h]
    pos = [0, iconShiftY]
    image = Picture($"{imgName}:{w}:{h}:P")
  }.__update(iconBase)
}

function mkDynamicCurrencyIcon(curId, size, iconShiftY, scale, aspectRatio = 1.0) {
  let w = round(size[1] * scale).tointeger()
  let h = round(w * 1.0 / aspectRatio).tointeger()
  let cfg = Computed(@() getCurrencyGoodsPresentation(curId, eventSeason.get())?[0])
  return @() {
    watch = cfg
    size = [w, h]
    pos = [0, iconShiftY]
    image = Picture($"ui/gameuiskin#{cfg.get()?.img}:{w}:{h}:P")
    fallbackImage = cfg.get()?.fallbackImg ? Picture($"ui/gameuiskin#{cfg.get()?.fallbackImg}:{w}:{h}:P") : null
  }.__update(iconBase)
}

let defCurrencyImgCtor = @(id, size, iconShiftY) mkOtherCurrencyIcon(size, iconShiftY, getCurrencyImage(id), 0.8)
let currencyImgCtors = {
  gold = @(size, iconShiftY) mkGoldOrWpIcon(size, iconShiftY, "shop_eagles_02.avif")
  wp = @(size, iconShiftY) mkGoldOrWpIcon(size, iconShiftY, "shop_lions_02.avif")
  warbond = @(size, iconShiftY) mkDynamicCurrencyIcon("warbond", size, iconShiftY, 0.85)
  eventKey = @(size, iconShiftY) mkDynamicCurrencyIcon("eventKey", size, iconShiftY, 0.65)
}

function mkRewardPlateCurrencyImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  return {
    size
    clipChildren = true
    children = currencyImgCtors?[r.id](size, iconShiftY)
      ?? defCurrencyImgCtor(r.id, size, iconShiftY)
  }
}

let mkRewardCurrencyImage = @(id, size) currencyImgCtors?[id]([size, size], 0)

function mkRewardPlateCurrencyTexts(r, rStyle) {
  let { labelCurrencyNeedCompact } = rStyle
  let countText = "countRange" in r
      ? "".concat(shortTextFromNum(r.count), "-", shortTextFromNum(r.countRange))
    : labelCurrencyNeedCompact
      ? shortTextFromNum(r.count)
    : decimalFormat(r.count)
  return mkRewardLabel([
    mkCommonLabelText(countText, rStyle)
  ])
}

// PREMIUM ////////////////////////////////////////////////////////////////////

function mkRewardPlatePremiumImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  let w = round(size[1] * 0.77).tointeger()
  let h = round(w / 286.0 * 197).tointeger()
  return {
    size
    children = iconBase.__merge({
      size = [w, h]
      pos = [ 0, iconShiftY ]
      image = Picture($"ui/gameuiskin#premium_active_big.avif:{w}:{h}:P")
    })
  }
}

function mkRewardPlatePremiumTexts(r, rStyle) {
  let days = r?.countRange && r.count != r?.countRange
    ? $"{r.count}-{r.countRange}"
    : $"{r.count}"
  return mkRewardLabel(mkCommonLabelText("".concat(days, loc("measureUnits/days")), rStyle))
}

// DECORATOR //////////////////////////////////////////////////////////////////

let mkDecoratorIconAvatar = @(decoratorId, _rStyle, size) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"{getAvatarImage(decoratorId)}:0:P")
}

let decoratorFontIconBase = {
  size = [flex(), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
}

let mkDecoratorIconTitle = @(decoratorId, rStyle, size) decoratorFontIconBase.__merge(
  {
    pos = [ 0, rStyle.iconShiftY ]
    behavior = Behaviors.Marquee
    speed = hdpx(30)
    delay = defMarqueeDelay
    text = loc($"title/{decoratorId}")
  },
  getFontToFitWidth({ rendObj = ROBJ_TEXT, text = loc($"title/{decoratorId}") }.__update(fontLabelBig),
    size[0] - textPadding[1] * 2, [fontLabel, fontLabelBig]))

let mkDecoratorIconNickFrame = @(decoratorId, rStyle, size) decoratorFontIconBase.__merge({
  pos = [ 0, rStyle.iconShiftY ]
  text = frameNick("", decoratorId)
  font = fontLabel.font
  fontSize = round(size[0] / 2.75)
})

let decoratorIconContentCtors = {
  avatar    = mkDecoratorIconAvatar
  title     = mkDecoratorIconTitle
  nickFrame = mkDecoratorIconNickFrame
}

function mkRewardPlateDecoratorImage(r, rStyle) {
  let { id } = r
  let size = getRewardPlateSize(r.slots, rStyle)
  let decoratorType = Computed(@() (allDecorators.value?[id].dType))
  let comp = { watch = decoratorType }
  return @() decoratorType.value == null ? comp : comp.__update({
    size
    children = decoratorIconContentCtors?[decoratorType.value](id, rStyle, size)
  })
}

function mkRewardPlateDecoratorTexts(r, rStyle) {
  let { id } = r
  let decoratorType = Computed(@() (allDecorators.value?[id].dType))
  let comp = { watch = decoratorType }
  return @() decoratorType.value == null ? comp : comp.__update(mkRewardLabel(
    mkCommonLabelTextMarquee(loc($"decorator/{allDecorators.value?[id].dType}"), rStyle)))
}

// ITEM ///////////////////////////////////////////////////////////////////////

function mkRewardPlateItemImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  let iconSize = round(size[1] * 0.55).tointeger()
  return {
    size
    clipChildren = true
    children = mkCurrencyImage(r.id, iconSize, { hplace = ALIGN_CENTER, pos = [ 0, iconShiftY ] })
  }
}

// LOOTBOX ////////////////////////////////////////////////////////////////////

function mkRewardPlateLootboxImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  let iconSize = round(size[1] * 0.67).tointeger()
  return {
    size
    children = mkLoootboxImage(r.id, iconSize,
      { pos = [ 0, iconShiftY ] }.__merge(iconBase))
  }
}

// BOOSTER ////////////////////////////////////////////////////////////////////

function mkRewardPlateBoosterImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  let iconSize = round(size[1] * 0.67).tointeger()
  return {
    size
    children = iconBase.__merge({
      size = [iconSize, iconSize]
      pos = [ 0, iconShiftY ]
      image = Picture($"{getBoosterIcon(r.id)}:{iconSize}:{iconSize}:P")
    })
  }
}

// UNIT ///////////////////////////////////////////////////////////////////////

function mkRewardPlateUnitImageImpl(r, rStyle, isUpgraded) {
  let unit = Computed(@() serverConfigs.value?.allUnits?[r.id].__merge({ isUpgraded }))
  let comp = { watch = unit }
  return @() unit.value == null ? comp : comp.__update({
    size = getRewardPlateSize(r.slots, rStyle)
    children = [
      mkUnitBg(unit.value)
      mkUnitImage(unit.value)
    ]
  })
}

// STAT ///////////////////////////////////////////////////////////////////////

function mkRewardPlateStatImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  let w = round(size[1] * 0.82).tointeger()
  let h = round(w / 286.0 * 197).tointeger()
  return {
    size
    children = iconBase.__merge({
      size = [w, h]
      pos = [ 0, iconShiftY ]
      image = Picture($"{getStatsImage(r.id)}:{w}:{h}:P")
    })
  }
}

// SKIN ///////////////////////////////////////////////////////////////////////

function mkRewardPlateSkinImage(r, rStyle) {
  let { id, subId = "" } = r
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  let iconSize = size.map(@(v) (v * 0.55).tointeger())
  let skinPresentation = getSkinPresentation(id, subId)

  return {
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = iconSize
      pos = [0, iconShiftY * 1.2]
      rendObj = ROBJ_MASK
      image = Picture($"ui/gameuiskin#slot_mask.svg:{iconSize[0]}:{iconSize[1]}:P")
      children = iconBase.__merge({
        size = iconSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{skinPresentation.image}:{iconSize[0]}:{iconSize[1]}:P")
      })
    }
  }
}

function mkRewardPlateSkinTexts(r, rStyle) {
  let { id } = r
  return mkRewardLabel(mkCommonLabelTextMarquee(loc(getUnitLocId(id)), rStyle))
}

//  UNIT ///////////////////////////////////////////////////////////////////////

let mkRewardPlateUnitImage = @(r, rStyle) mkRewardPlateUnitImageImpl(r, rStyle, false)
let mkRewardPlateUnitUpgradeImage = @(r, rStyle) mkRewardPlateUnitImageImpl(r, rStyle, true)

function mkUnitTextsImpl(r, rStyle, isUpgraded) {
  let unit = Computed(@() serverConfigs.value?.allUnits?[r.id].__merge({ isUpgraded }))
  let size = getRewardPlateSize(r.slots, rStyle)
  return function() {
    let res = { watch = unit }
    if (unit.value == null)
      return res
    let unitNameLoc = loc(getUnitLocId(unit.value))
    return res.__update({
      size
      padding = textPadding
      clipChildren = true
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          pos = [0, hdpx(3)]
          flow = FLOW_VERTICAL
          halign = ALIGN_RIGHT
          children = [
            mkUnitNameText(unitNameLoc, size, rStyle)
            mkPlateText(getUnitClassFontIcon(unit.value), fontLabel)
          ]
        }
        {
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          children = mkGradRankSmall(unit.value.mRank)
        }
      ]
    })
  }
}

let mkRewardPlateUnitTexts = @(r, rStyle) mkUnitTextsImpl(r, rStyle, false)
let mkRewardPlateUnitUpgradeTexts = @(r, rStyle) mkUnitTextsImpl(r, rStyle, true)

//  BLUEPRINTS ////////////////////////////////////////////////////////////////

function mkRewardPlateBlueprintImage(r, rStyle) {
  let { id } = r
  let size = getRewardPlateSize(r.slots, rStyle)
  let imageW = size[0]
  let imageH = size[1] - progressBarHeight
  let unitNameLoc = loc(getUnitLocId(id))
  return {
    size = [imageW,imageH]
    rendObj = ROBJ_IMAGE
    fallbackImage = Picture($"ui/unitskin#blueprint_default.avif:{imageW}:{imageH}:P")
    image = Picture($"ui/unitskin#blueprint_{id}.avif:{imageW}:{imageH}:P")
    halign = ALIGN_RIGHT
    valign = ALIGN_TOP
    children = mkUnitNameText(unitNameLoc, size, rStyle).__update({ padding = textPadding })
  }
}

function mkRewardPlateBlueprintTexts(r, rStyle) {
  let available = Computed(@() servProfile.get()?.blueprints?[r.id] ?? 0)
  let total = Computed(@() serverConfigs.get()?.allBlueprints?[r.id].targetCount ?? 1)
  let unitRank = Computed(@() serverConfigs.value?.allUnits?[r.id]?.mRank)
  let isAllReceived = ("dropLimit" in r && "received" in r)
    ? r.dropLimit != NO_DROP_LIMIT && r.dropLimit <= r.received
    : false

  return {
    size = flex()
    children = [
      @() {
        watch = [available, total]
        size = flex()
        valign = ALIGN_BOTTOM
        flow = FLOW_VERTICAL
        children = [
          mkProgressLabel(available.get(), total.get(), rStyle)
          isAllReceived
            ? mkProgressBar(available.get(), total.get())
            : mkProgressBarWithForecast(r.count, available.get(), total.get())
        ]
      }
      @() {
        watch = unitRank
        size = flex()
        valign = ALIGN_BOTTOM
        halign = ALIGN_RIGHT
        flow = FLOW_VERTICAL
        padding = [0, hdpx(5)]
        children = [
          unitRank.get()
            ? mkGradRankSmall(unitRank.get()).__update({ fontSize = rStyle.textStyle.fontSize, pos = [0, hdpx(5)] })
            : null
          mkProgressBarText(r, rStyle)
        ]
      }
    ]
  }
}

// UNKNOWN ////////////////////////////////////////////////////////////////////

function mkRewardPlateUnknownImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  let iconSize = round(size[1] * 0.6).tointeger()
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

function mkRewardPlateBg(r, rStyle) {
  let size = getRewardPlateSize(r.slots, rStyle)
  return {
    size
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/images/offer_item_slot_bg.avif:{size[0]}:{size[1]}:P")
  }
}

function mkRewardPlateBgVip(r, rStyle) {
  let size = getRewardPlateSize(r.slots, rStyle)
  return {
    size
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/images/offer_item_slot_bg_vip.avif:{size[0]}:{size[1]}:P")
  }
}

let battleModeViewCtors = {
  eventUnit = {
    image = mkBattleModRewardUnitImage
    texts = mkBattleModEventUnitText
  }
  common = {
    image = mkBattleModCommonImage
    texts = mkBattleModCommonText
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
  stat = {
    image = mkRewardPlateStatImage
    texts = mkRewardPlateCountText
  }
  booster = {
    image = mkRewardPlateBoosterImage
    texts = mkRewardPlateCountText
  }
  skin = {
    image = mkRewardPlateSkinImage
    texts = mkRewardPlateSkinTexts
  }
  battleMod = {
    image = function(r, rStyle) {
      let battleMod = getBattleModPresentation(r.id)
      return battleMod?.viewType in battleModeViewCtors
        ? battleModeViewCtors[battleMod.viewType].image(battleMod, rStyle, r.slots)
        : mkRewardPlateUnknownImage(r, rStyle)
    }
    texts = function(r, rStyle) {
      let battleMod = getBattleModPresentation(r.id)
      return battleMod?.viewType in battleModeViewCtors
        ? battleModeViewCtors[battleMod.viewType].texts(battleMod, rStyle, r.slots)
        : mkRewardPlateCountText(r, rStyle)
    }
  }
  blueprint = {
    image = mkRewardPlateBlueprintImage
    texts = mkRewardPlateBlueprintTexts
  }
}

let mkRewardPlateImage = @(r, rStyle) (rewardPlateCtors?[r?.rType] ?? rewardPlateCtors.unknown).image(r, rStyle)
let mkRewardPlateTexts = @(r, rStyle) (rewardPlateCtors?[r?.rType] ?? rewardPlateCtors.unknown).texts(r, rStyle)

let mkRewardPlate = @(r, rStyle, ovr = {}) {
  transform = {}
  children = [
    mkRewardPlateBg(r, rStyle)
    mkRewardPlateImage(r, rStyle)
    mkRewardPlateTexts(r, rStyle)
  ]
}.__update(ovr)

let mkRewardPlateVip = @(r, rStyle, ovr = {}) {
  transform = {}
  children = [
    mkRewardPlateBgVip(r, rStyle)
    mkRewardPlateImage(r, rStyle)
    mkRewardPlateTexts(r, rStyle)
  ]
}.__update(ovr)

let mkRewardLocked = @(rStyle) {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x60000000
  children = {
    size = [rStyle.markSize, rStyle.markSize]
    margin = hdpx(8)
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"ui/gameuiskin#lock_icon.svg:{rStyle.markSize}:{rStyle.markSize}:P")
  }
}

return {
  REWARD_STYLE_TINY
  REWARD_STYLE_SMALL
  REWARD_STYLE_MEDIUM

  mkRewardDisabledBkg
  mkRewardSearchPlate
  getRewardPlateSize
  mkRewardPlate
  mkRewardPlateVip
  mkRewardPlateBg
  mkRewardPlateImage
  mkRewardCurrencyImage
  mkRewardPlateTexts
  mkRewardReceivedMark
  mkRewardFixedIcon
  mkReceivedCounter
  mkRewardLocked
  mkProgressLabel
  mkProgressBarWithForecast
  mkProgressBarText

  decoratorIconContentCtors
}
