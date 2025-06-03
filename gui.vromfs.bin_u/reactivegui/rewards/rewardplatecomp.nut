from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { AIR, TANK } = require("%appGlobals/unitConst.nut")
let { EVENT_KEY, PLATINUM, GOLD, WARBOND } = require("%appGlobals/currenciesState.nut")
let { getCurrencyBigIcon } = require("%appGlobals/config/currencyPresentation.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { mkCurrencyFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getUnitLocId, getUnitClassFontIcon, getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { mkLoootboxImage } = require("%appGlobals/config/lootboxPresentation.nut")
let { getStatsImage } = require("%appGlobals/config/rewardStatsPresentation.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { getBattleModPresentation } = require("%appGlobals/config/battleModPresentation.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { decimalFormat, shortTextFromNum } = require("%rGui/textFormatByLang.nut")
let { REWARD_STYLE_TINY, REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM,
  getRewardPlateSize, progressBarHeight, rewardTicketDefaultSlots
} = require("rewardStyles.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { mkUnitBg, mkUnitImage, mkPlateText } = require("%rGui/unit/components/unitPlateComp.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")
let { getFontToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { mkBattleModEventUnitText, mkBattleModRewardUnitImage, mkBattleModCommonText,
  mkBattleModCommonImage } = require("%rGui/rewards/battleModComp.nut")
let { NO_DROP_LIMIT, shopGoodsToRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { mkRewardSlider } = require("%rGui/rewards/components/mkRewardSlider.nut")
let { openRewardPrizeView } = require("%rGui/rewards/rewardPrizeView.nut")
let { allShopGoods, calculateNewGoodsDiscount } = require("%rGui/shop/shopState.nut")
let { discountTag } = require("%rGui/components/discountTag.nut")
let { getBestUnitByGoods } = require("%rGui/shop/goodsUtils.nut")
let { SGT_UNIT } = require("%rGui/shop/shopCommon.nut")
let { mkBgImg, mkFitCenterImg, offerPad } = require("%rGui/shop/goodsView/sharedParts.nut")
let { activeOffersByGoods } = require("%rGui/shop/offerByGoodsState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { withGlareEffect } = require("%rGui/components/glare.nut")


let currenciesOnOfferBanner = [PLATINUM, EVENT_KEY, GOLD, WARBOND]
let glareWidth = sh(8)
let commonOfferCurrencyIconSize = hdpxi(160)
let smallOfferCurrencyIconSize = hdpxi(100)
let textPadding = [0, hdpx(5)]
let cornerIconMargin = hdpx(5)
let fontLabelBig = fontSmall
let transparentBlackColor = 0x80000000

let iconBase = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  keepAspect = true
}

let mkCommonLabelText = @(text, rStyle) {
  maxWidth = rStyle.boxSize
  rendObj = ROBJ_TEXT
  text
}.__update(getFontToFitWidth({ rendObj = ROBJ_TEXT, text }.__update(rStyle.textStyle),
  rStyle.boxSize - textPadding[1] * 2, [rStyle.textStyleSmall, rStyle.textStyle]))

let mkCommonLabelTextMarquee = @(text, rStyle) {
  maxWidth = rStyle.boxSize - textPadding[1] * 2
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  speed = hdpx(30)
  delay = defMarqueeDelay
  text
}.__update(rStyle.textStyleSmall)

let mkRewardLabel = @(children, rStyle, needPadding = true) {
  size = [flex(), rStyle.labelHeight]
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

let mkRewardTextLabel = @(text, rStyle) mkRewardLabel(mkCommonLabelText(text, rStyle), rStyle)

function mkRewardSearchPlate(rStyle) {
  let { markSmallSize, markSize } = rStyle
  return {
    size = [markSize, markSize]
    fillColor = transparentBlackColor
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(1)
    commands = [
      [VECTOR_ELLIPSE, 50, 50, 50, 50],
    ]
    children = {
      size = [markSmallSize, markSmallSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#btn_search.svg:{markSmallSize}:{markSmallSize}:P")
      color = 0xFFFFFFFF
    }
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

let mkProgressLabel = @(available, total, rStyle) {
  size = [flex(), rStyle.labelHeight]
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
  mkRewardTextLabel(
    "countRange" in r
        ? "".concat(decimalFormat(r.count), "-", decimalFormat(r.countRange))
      : decimalFormat(r.count),
    rStyle)


let mkRewardFixedIcon = @(rStyle) {
  size = [rStyle.markSize, rStyle.markSize]
  margin = cornerIconMargin
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  imageValign = ALIGN_TOP
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



function mkGoldOrWpIcon(size, iconShiftY, icon) {
  let w = round(size[1] * 1.1).tointeger()
  let h = round(w / 469.0 * 291).tointeger()
  return {
    size = [w, h]
    pos = [w * 0.12, iconShiftY + (h * -0.07)]
    image = Picture($"{icon}:{w}:{h}:P")
  }.__update(iconBase)
}

function mkCommonCurrencyIcon(curId, amount, pSize, iconShiftY, scale) {
  let size = round(pSize[1] * scale).tointeger()
  let fullId = mkCurrencyFullId(curId)
  let cfg = Computed(@() getCurrencyGoodsPresentation(fullId.get(), amount))
  return @() {
    watch = cfg
    size = [size, size]
    pos = [0, iconShiftY]
    image = Picture($"ui/gameuiskin#{cfg.get().img}:{size}:{size}:P")
    fallbackImage = cfg.get()?.fallbackImg ? Picture($"ui/gameuiskin#{cfg.get().fallbackImg}:{size}:{size}:P") : null
  }.__update(iconBase)
}

let defCurrencyImgCtor = @(id, amount, size, iconShiftY) mkCommonCurrencyIcon(id, amount, size, iconShiftY, 0.85)
let currencyImgCtors = {
  gold = @(id, _, size, iconShiftY) mkGoldOrWpIcon(size, iconShiftY, getCurrencyBigIcon(id)) 
  wp = @(id, _, size, iconShiftY) mkGoldOrWpIcon(size, iconShiftY, getCurrencyBigIcon(id)) 
  eventKey = @(id, amount, size, iconShiftY) mkCommonCurrencyIcon(id, amount, size, iconShiftY, 0.65)
}

function mkRewardPlateCurrencyImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let { id, count } = r
  let size = getRewardPlateSize(r.slots, rStyle)
  return {
    size
    clipChildren = true
    children = currencyImgCtors?[id](id, count, size, iconShiftY)
      ?? defCurrencyImgCtor(id, count, size, iconShiftY)
  }
}

let mkRewardCurrencyImage = @(id, amount, size) currencyImgCtors?[id](id, amount, size, 0)

function mkRewardPlateCurrencyTexts(r, rStyle) {
  let { labelCurrencyNeedCompact } = rStyle
  let countText = "countRange" in r
      ? "".concat(shortTextFromNum(r.count), "-", shortTextFromNum(r.countRange))
    : labelCurrencyNeedCompact
      ? shortTextFromNum(r.count)
    : decimalFormat(r.count)
  return mkRewardLabel(mkCommonLabelText(countText, rStyle), rStyle)
}



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
  return mkRewardTextLabel("".concat(days, loc("measureUnits/days")), rStyle)
}



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
    pos = [0, rStyle.iconShiftY]
    valign = ALIGN_CENTER
    rendObj = ROBJ_TEXTAREA
    behavior = [Behaviors.TextArea, Behaviors.Marquee]
    delay = defMarqueeDelay
    text = loc($"title/{decoratorId}")
  },
  getFontToFitWidth({ rendObj = ROBJ_TEXT, text = loc($"title/{decoratorId}") }.__update(fontLabelBig),
    size[0] - textPadding[1] * 2, [rStyle.textStyle, fontLabelBig]))

let mkDecoratorIconNickFrame = @(decoratorId, rStyle, size) decoratorFontIconBase.__merge({
  pos = [ 0, rStyle.iconShiftY ]
  text = frameNick("", decoratorId)
  font = rStyle.textStyle.font
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
  return @() decoratorType.value == null ? comp
    : comp.__update(
        mkRewardLabel(mkCommonLabelTextMarquee(loc($"decorator/{allDecorators.value?[id].dType}"), rStyle), rStyle))
}



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



function mkRewardPlateLootboxImage(r, rStyle) {
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  let iconSize = round(size[1] * 0.67).tointeger()
  return {
    size
    children = mkLoootboxImage(r.id, iconSize).__update({ pos = [ 0, iconShiftY ] }).__merge(iconBase)
  }
}



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



function mkRewardPlateSkinImage(r, rStyle) {
  let { id, subId = "" } = r
  let { iconShiftY } = rStyle
  let size = getRewardPlateSize(r.slots, rStyle)
  let iconSize = size.map(@(v) (v * 0.55).tointeger())
  let iconBorderRadius = round(iconSize[0]*0.2).tointeger()
  let skinPresentation = getSkinPresentation(id, subId)

  return {
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = iconSize
      pos = [0, iconShiftY * 1.2]
      rendObj = ROBJ_BOX
      fillColor = 0xFFFFFFFF
      borderRadius = iconBorderRadius
      image = Picture($"ui/gameuiskin#{skinPresentation.image}:{iconSize[0]}:{iconSize[1]}:P")
    }
  }
}

let mkRewardPlateSkinTexts = @(r, rStyle)
  mkRewardLabel(mkCommonLabelTextMarquee(loc(getUnitLocId(r.id)), rStyle), rStyle)



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
            mkPlateText(getUnitClassFontIcon(unit.value), rStyle.textStyle)
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



function mkRewardPlateBlueprintImage(r, rStyle) {
  let { id } = r
  let size = getRewardPlateSize(r.slots, rStyle)
  let imageW = size[0]
  let imageH = size[1] - progressBarHeight
  let unitNameLoc = loc(getUnitLocId(id))
  let image = getUnitPresentation(id).blueprintImage

  return {
    size = [imageW,imageH]
    rendObj = ROBJ_IMAGE
    fallbackImage = Picture($"ui/unitskin#blueprint_default.avif:{imageW}:{imageH}:P")
    image = Picture($"{image}:{imageW}:{imageH}:P")
    halign = ALIGN_RIGHT
    valign = ALIGN_TOP
    children = mkUnitNameText(unitNameLoc, size, rStyle).__update({ padding = textPadding })
  }
}

function mkRewardPlateBlueprintTexts(r, rStyle) {
  let { id } = r
  let available = Computed(@() servProfile.get()?.blueprints?[id] ?? 0)
  let total = Computed(@() serverConfigs.get()?.allBlueprints?[id].targetCount ?? 1)
  let unitRank = Computed(@() serverConfigs.get()?.allUnits?[id]?.mRank)
  let hasBlueprintUnit = Computed(@() id in campMyUnits.get())
  let isAllReceived = ("dropLimit" in r && "received" in r)
    ? r.dropLimit != NO_DROP_LIMIT && r.dropLimit <= r.received
    : false

  return {
    size = flex()
    children = [
      @() {
        watch = [available, total, hasBlueprintUnit]
        size = flex()
        valign = ALIGN_BOTTOM
        flow = FLOW_VERTICAL
        children = hasBlueprintUnit.get()
          ? [
              mkProgressLabel(total.get(), total.get(), rStyle)
              mkProgressBar(total.get(), total.get())
            ]
          : [
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



function mkRewardPlatePrizeTicketImage(r, rStyle, rewardCtors) {
  let { prizeTicketsCfg = {} } = serverConfigs.get()
  let { needShowPreview = true } = rStyle
  let { id } = r

  if (!id || id not in prizeTicketsCfg)
    return null

  let rewards = []
  foreach(variant in (prizeTicketsCfg?[id].variants ?? [])) {
    let reward = variant.top()
    rewards.append({ slots = rewardTicketDefaultSlots, rType = reward.gType }.__merge(reward))
  }

  return mkRewardSlider(rewards, rewardCtors, @() !needShowPreview ? null
    : openRewardPrizeView(rewards, rewardCtors), rStyle)
}


let unitOfferImageOvrByType = {
  [AIR] = {
    size = [pw(90), ph(90)]
    imageHalign = ALIGN_LEFT
    vplace = ALIGN_CENTER
  }
}

let mkOfferCurrencyIcon = @(currencyId, amount, iconSize) {
  margin = offerPad
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  children = mkRewardCurrencyImage(currencyId, amount, [iconSize, iconSize])
  keepAspect = true
}

let mkDiscountOfferWrap = @(content, size) bgShaded.__merge({
  size
  transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  children = withGlareEffect(
    { size = flex(), children = content },
    size[0],
    null,
    { glareWidth }
  ).__update({ size = flex() })
})

let mkDiscountOfferTag = @(discount) discountTag(discount, {
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  pos = [0, 0]
  size = [hdpx(93), hdpx(46)]
}, { pos = null }.__update(fontTinyAccented))

let mkDiscountOfferRank = @(unit) {
  padding = hdpx(5)
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = mkGradRankSmall(unit.mRank)
}

let mkDiscountOfferText = @(title, rStyle) {
  size = [flex(), SIZE_TO_CONTENT]
  margin = hdpx(5)
  rendObj = ROBJ_TEXTAREA
  behavior = [Behaviors.TextArea, Behaviors.Marquee]
  halign = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  maxWidth = hdpx(200)
  delay = defMarqueeDelay
  threshold = hdpx(2)
  speed = hdpx(30)
  text = utf8ToUpper(title)
}.__update(getFontToFitWidth({
      rendObj = ROBJ_TEXTAREA
      maxWidth = hdpx(200)
      text = utf8ToUpper(title)
    }.__update(rStyle.textStyle),
  rStyle.boxSize - textPadding[1] * 2, [rStyle.textStyleSmall, rStyle.textStyle]))

function mkDiscountOfferUnit(goods, discount, rStyle) {
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  let { currencies = {}, offerClass = null } = goods
  let p = getUnitPresentation(unit)
  let bgImg = offerClass == "seasonal" ? "ui/gameuiskin#offer_bg_green.avif"
    : unit?.unitType == TANK || unit?.unitType == AIR ? "ui/gameuiskin#offer_bg_yellow.avif"
    : "ui/gameuiskin#offer_bg_blue.avif"
  let currencyId = currenciesOnOfferBanner.findvalue(@(v) v in currencies)
  let image = mkFitCenterImg(unit?.isUpgraded ? p.upgradedImage : p.image,
    unitOfferImageOvrByType?[unit?.unitType] ?? {}).__update({ fallbackImage = Picture(p.image) })
  let imageOffset = currencyId == null || unit?.unitType == TANK ? 0
    : hdpx(20)
  let size = getRewardPlateSize(2, rStyle)
  return mkDiscountOfferWrap(unit == null ? null
    : [
        mkBgImg(bgImg)
        currencyId == null ? null : mkOfferCurrencyIcon(currencyId, currencies[currencyId],
          commonOfferCurrencyIconSize > rStyle.boxSize ? smallOfferCurrencyIconSize : commonOfferCurrencyIconSize)
        imageOffset == 0 ? image : image.__update({ margin = [0, imageOffset, 0, 0] })
        mkDiscountOfferText(loc("discountUpgrade"), rStyle)
        mkDiscountOfferRank(unit)
        mkDiscountOfferTag(discount)
      ], size)
}

let discountOfferCtors = {
  [SGT_UNIT] = mkDiscountOfferUnit
}

function mkRewardPlateDiscount(previewReward, discount, rewardCtors, rewardStyle) {
  let mkPlateImage = @(r, rStyle) (rewardCtors?[r?.rType] ?? rewardCtors.unknown).image(r, rStyle)
  let mkPlateTexts = @(r, rStyle) (rewardCtors?[r?.rType] ?? rewardCtors.unknown).texts(r, rStyle)

  let size = getRewardPlateSize(previewReward?.slots ?? 1, rewardStyle)

  let mkPlate = @(r, rDiscount, rStyle, rSize) {
    transform = {}
    children = [
      {
        size = rSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/images/offer_item_slot_bg.avif:{rSize[0]}:{rSize[1]}:P")
      }
      mkPlateImage(r, rStyle)
      mkPlateTexts(r, rStyle)
      mkDiscountOfferTag(rDiscount)
    ]
  }

  return mkPlate(previewReward, discount, rewardStyle, size)
}

let mkRewardPlateDiscountImage = @(reward, rStyle, rewardCtors) function() {
  let goodsId = serverConfigs.get()?.personalDiscounts.findindex(@(list) list.findindex(@(v) v.id == reward.id) != null)
  let goods = allShopGoods.get()?[goodsId] ?? {}
  let offer = activeOffersByGoods.get()?[goodsId] ?? goods.__merge({ offerClass = "seasonal" }) 
  let needShowAsOffer = !!goods?.meta.showAsOffer

  let previewReward = shopGoodsToRewardsViewInfo(goods).sort(sortRewardsViewInfo)[0]
  let personalFinalPrice = serverConfigs.get()?.personalDiscounts?[goodsId].findvalue(@(v) v.id == reward.id).price ?? 0
  let newDiscount = calculateNewGoodsDiscount(goods?.price.price ?? 0, goods?.discountInPercent, personalFinalPrice)

  return {
    watch = [serverConfigs, allShopGoods, activeOffersByGoods]
    size = flex()
    children = !goodsId ? null
      : !needShowAsOffer || goods?.gtype not in discountOfferCtors
        ? mkRewardPlateDiscount(previewReward, newDiscount, rewardCtors, rStyle)
      : discountOfferCtors[offer.gtype](offer, newDiscount, rStyle)
  }
}



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

let simpleRewardPlateCtors = {
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

let complexRewardPlateCtors = {
  prizeTicket = {
    image = @(r, rStyle) mkRewardPlatePrizeTicketImage(r, rStyle, simpleRewardPlateCtors)
    texts = @(_, _) null
  }
  discount = {
    image = @(r, rStyle) mkRewardPlateDiscountImage(r, rStyle, simpleRewardPlateCtors)
    texts = mkRewardPlateUnitTexts
  }
}

let rewardPlateCtors = {}.__merge(simpleRewardPlateCtors, complexRewardPlateCtors)

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

let function mkRewardUnitFlag(unit, rStyle) {
  let operatorCountry = getUnitTagsCfg(unit.name)?.operatorCountry
  if (operatorCountry == "")
    return null
  let countryId = operatorCountry ?? unit.country
  if (countryId == null)
    return null
  let w = rStyle.markSize
  let h = round(w * (66.0 / 84)).tointeger()
  return {
    size = [w, h]
    margin = cornerIconMargin
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{countryId}.avif:{w}:{h}:P")
    fallbackImage = Picture($"ui/gameuiskin#menu_lang.svg:{w}:{h}:P")
    keepAspect = true
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
  mkProgressBar
  mkRewardTextLabel
  mkRewardUnitFlag

  decoratorIconContentCtors
}
