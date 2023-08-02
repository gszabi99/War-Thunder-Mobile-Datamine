from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { frnd } = require("dagor.random")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { unseenPurchasesExt, markPurchasesSeen, hasActiveCustomUnseenView
} = require("unseenPurchasesState.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { bgShadedDark } = require("%rGui/style/backgrounds.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { getUnitPresentation, getPlatoonName } = require("%appGlobals/unitPresentation.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitBg, mkUnitImage, mkUnitTexts,
  mkPlatoonBgPlates, platoonPlatesGap, mkPlatoonPlateFrame
} = require("%rGui/unit/components/unitPlateComp.nut")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")

let knownGTypes = [ "currency", "premium", "item", "unitUpgrade", "unit", "unitMod", "unitLevel", "decorator" ]

let wndWidth = saSize[0]
let maxWndHeight = saSize[1]
let rewIconSize = hdpx(100)
let rewIconToTextGap = hdpx(29)
let rewIconsGap = hdpx(80)
let rewIconsRowToUnitPlatesGap = hdpx(60)
let rewIconsPerRow = ((wndWidth + rewIconsGap) / (rewIconSize + rewIconsGap)).tointeger()
let unitPlatesGap = hdpx(40)
let unitsPerRow = ((wndWidth + unitPlatesGap) / (unitPlateWidth + unitPlatesGap)).tointeger()

let fadedTextColor = 0xFFACACAC
let ANIM_SKIP = {}
let ANIM_SKIP_DELAY = {}

let aIntroTime = 0.2
let aRewardOpacityTime = 0.2
let aRewardScaleDelay = 0.05
let aRewardScaleUpTime = 0.05
let aRewardScaleDownTime = 0.23
let aRewardAnimTotalTime = aRewardScaleDelay + aRewardScaleUpTime + aRewardScaleDownTime
let aFlareDelay = 0.3
let aFlareUpTime = 0.3
let aFlareStayTime = 0.4
let aFlareDownTime = 0.5
let aFlareScaleMin = 0.5
let aFlareRotationSpeed = 600
let aRewardIconSelfScale = 1.4
let aRewardIconFlareScale = 4.0
let aUnitPlateFlareScale = 6.0
let aUnitPlateSelfScale = 1.1
let aRewardLabelDelay = aFlareDelay + aFlareUpTime + aFlareStayTime + 0.5 * aFlareDownTime
let aRewardLabelOpacityTime = 0.5 * aFlareDownTime
let aOutroExtraDelay = 1.5
let aTitleOpacityTime = 0.05
let aTitleScaleDelayTime = aTitleOpacityTime
let aTitleScaleUpTime = 0.15
let aTitleScaleDownTime = aTitleScaleUpTime
let aTitleScaleMin = 0.75
let aTitleScaleMax = 1.1

let orderByCurrency = { gold = 0, wp = 1 }

let stackData = Computed(function() {
  let stackRaw = {}
  foreach (purch in unseenPurchasesExt.value)
    foreach (data in purch.goods) {
      let { id, gType, count } = data
      if (gType not in stackRaw)
        stackRaw[gType] <- {}
      if (id not in stackRaw[gType])
        stackRaw[gType][id] <- { id, gType, count, order = -1 }
      else
        stackRaw[gType][id].count += count
    }

  foreach (gType, _ in stackRaw)
    if (!knownGTypes.contains(gType))
      logerr($"Unknown reward goods type: {gType}")

  let stacksSorted = stackRaw.map(@(v) v.values())
  stacksSorted?.currency.each(@(v) v.order = orderByCurrency?[v.id] ?? orderByCurrency.len())
  stacksSorted?.item.each(@(v) v.order = orderByItems?[v.id] ?? orderByItems.len())
  foreach (arr in stacksSorted)
    arr.sort(@(a, b) a.order <=> b.order)

  let { currency = [], premium = [], item = [], unitUpgrade = [], unit = [], decorator = [] } = stacksSorted
  let rewardIcons = [].extend(currency, premium, item, decorator)
  let unitPlates = [].extend(unitUpgrade, unit)

  let idxOffsetPlates = rewardIcons.len()
  rewardIcons.each(@(v, i) v.idx <- i)
  unitPlates.each(@(v, i) v.idx <- idxOffsetPlates + i)

  let rewardIconsStartDelay = aIntroTime
  let unitPlatesStartDelay = rewardIconsStartDelay + (rewardIcons.len() * aRewardAnimTotalTime)
  let outroDelay = unitPlatesStartDelay + (unitPlates.len() * aRewardAnimTotalTime) + aOutroExtraDelay
  rewardIcons.each(@(v, i) v.startDelay <- rewardIconsStartDelay + (i * aRewardAnimTotalTime))
  unitPlates.each(@(v, i) v.startDelay <- unitPlatesStartDelay + (i * aRewardAnimTotalTime))

  return {
    outroDelay
  }.__update({
    rewardIcons
    unitPlates
  }.filter(@(v) v.len() != 0))
})

let needShow = keepref(Computed(@() !hasActiveCustomUnseenView.value
  && unseenPurchasesExt.value.len() != 0
  && isInMenu.value && isLoggedIn.value))

let WND_UID = "unseenPurchaseWindow"
let close = @() removeModalWindow(WND_UID)

let isAnimFinished = Watched(false)
needShow.subscribe(@(v) v ? isAnimFinished(false) : null)

let mkRewardAnimProps = @(startDelay, scaleTo) {
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0,
      duration = startDelay,
      play = true, trigger = ANIM_SKIP }
    { prop = AnimProp.opacity, from = 0, to = 1,
      delay = startDelay, duration = aRewardOpacityTime,
      play = true, trigger = ANIM_SKIP_DELAY }
    { prop = AnimProp.scale, from = [1, 1], to = [1, 1],
      duration = startDelay + aRewardScaleDelay,
      play = true, trigger = ANIM_SKIP }
    { prop = AnimProp.scale, from = [1, 1], to = [scaleTo, scaleTo], easing = OutCubic,
      delay = startDelay + aRewardScaleDelay, duration = aRewardScaleUpTime,
      play = true, trigger = ANIM_SKIP }
    { prop = AnimProp.scale, from = [scaleTo, scaleTo], to = [1, 1], easing = InCubic,
      delay = startDelay + aRewardScaleDelay + aRewardScaleUpTime, duration = aRewardScaleDownTime,
      play = true, trigger = ANIM_SKIP }
  ]
}

let function mkHighlight(startDelay, sizeMul) {
  let highlightSize = hdpx(sizeMul * rewIconSize)
  let startRotation = frnd() * 360
  return {
    size = [highlightSize, highlightSize]
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture("ui/images/effects/open_flash.avif")
        opacity = 0

        transform = {}
        animations = [
          { prop = AnimProp.opacity, from = 0, to = 0,
            duration = startDelay + aFlareDelay
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.opacity, from = 0, to = 1, easing = OutCubic,
            delay = startDelay + aFlareDelay, duration = aFlareUpTime,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.opacity, from = 1, to = 1,
            delay = startDelay + aFlareDelay + aFlareUpTime, duration = aFlareStayTime,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.opacity, from = 1, to = 0, easing = InCubic,
            delay = startDelay + aFlareDelay + aFlareUpTime + aFlareStayTime, duration = aFlareDownTime,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.scale, from = [aFlareScaleMin, aFlareScaleMin], to = [aFlareScaleMin, aFlareScaleMin],
            duration = startDelay + aFlareDelay,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.scale, from = [aFlareScaleMin, aFlareScaleMin], to = [1, 1], easing = OutCubic,
            delay = startDelay + aFlareDelay, duration = aFlareUpTime,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.scale, from = [1, 1], to = [1, 1], easing = InCubic,
            delay = startDelay + aFlareDelay + aFlareUpTime, duration = aFlareStayTime,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.scale, from = [1, 1], to = [aFlareScaleMin, aFlareScaleMin], easing = InCubic,
            delay = startDelay + aFlareDelay + aFlareUpTime + aFlareStayTime, duration = aFlareDownTime,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.rotate, from = startRotation, to = startRotation + (aFlareDelay * aFlareRotationSpeed),
            delay = startDelay + aFlareDelay, duration = aFlareUpTime + aFlareStayTime + aFlareDownTime,
            play = true, trigger = ANIM_SKIP }
        ]
      }
    ]
  }
}

let function mkRerwardIcon(startDelay, imgPath, sizeMulX = 1.0, sizeMulY = 1.0) {
  let imgW = round(rewIconSize * sizeMulX)
  let imgH = round(rewIconSize * sizeMulY)
  return {
    size = [rewIconSize, rewIconSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkHighlight(startDelay, aRewardIconFlareScale)
      {
        size = [imgW, imgH]
        rendObj = ROBJ_IMAGE
        image = Picture($"{imgPath}:{imgW}:{imgH}:K:P")
        keepAspect = true
        color = 0xFFFFFFFF
      }.__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
    ]
  }
}

let decoratorIconByType = {
  nickFrame = @(decoratorId) frameNick(" ", decoratorId)
  title = @(decoratorId) loc($"title/{decoratorId}")
}

let function mkDecoratorRewardIcon(startDelay, decoratorId) {
  return {
    size = [SIZE_TO_CONTENT, rewIconSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      @() {
        watch = allDecorators
        size = [SIZE_TO_CONTENT, flex()]
        rendObj = ROBJ_TEXT
        text = decoratorIconByType?[allDecorators.value?[decoratorId].dType](decoratorId) ?? decoratorId
      }.__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale), fontBig)
    ]
  }
}

let mkCurrencyIcon = @(startDelay, id) {
  size = [rewIconSize, rewIconSize]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    mkHighlight(startDelay, aRewardIconFlareScale)
    mkCurrencyImage(id, rewIconSize, mkRewardAnimProps(startDelay, aRewardIconSelfScale))
  ]
}

let function mkRewardLabel(startDelay, text) {
  return {
    rendObj = ROBJ_TEXT
    color = 0xFFFFFFFF
    text

    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 0,
        duration = startDelay + aRewardLabelDelay,
        play = true, trigger = ANIM_SKIP }
      { prop = AnimProp.opacity, from = 0, to = 1,
        delay = startDelay + aRewardLabelDelay, duration = aRewardLabelOpacityTime,
        play = true, trigger = ANIM_SKIP_DELAY }
    ]
  }.__update(fontMediumShaded)
}

let mkDecoratorRewardLabel = @(startDelay, decoratorId)
  @() {
    watch = allDecorators
    children = mkRewardLabel(startDelay, loc($"decorator/{allDecorators.value?[decoratorId].dType}"))
  }

let rewardCtors = {
  currency = {
    mkIcon = @(rewardInfo) mkCurrencyIcon(rewardInfo.startDelay, rewardInfo.id)
    mkText = @(rewardInfo) mkRewardLabel(rewardInfo.startDelay, decimalFormat(rewardInfo.count))
  }
  premium = {
    mkIcon = @(rewardInfo) mkRerwardIcon(rewardInfo.startDelay, "ui/gameuiskin#premium_active.svg" , 1.43, 1.0)
    mkText = @(rewardInfo) mkRewardLabel(rewardInfo.startDelay,
      "".concat(rewardInfo.count, loc("measureUnits/days")))
  }
  item = {
    mkIcon = @(rewardInfo) mkCurrencyIcon(rewardInfo.startDelay, rewardInfo.id)
    mkText = @(rewardInfo) mkRewardLabel(rewardInfo.startDelay, decimalFormat(rewardInfo.count))
  }
  decorator = {
    mkIcon = @(rewardInfo) mkDecoratorRewardIcon(rewardInfo.startDelay, rewardInfo.id)
    mkText = @(rewardInfo) mkDecoratorRewardLabel(rewardInfo.startDelay, rewardInfo.id)
  }
}

let function mkRewardIconComp(rewardInfo) {
  let { mkIcon, mkText } = rewardCtors[rewardInfo.gType]

  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = rewIconToTextGap
    children = [
      mkIcon(rewardInfo)
      mkText(rewardInfo)
    ]
  }
}

let mkRewardIconsBlock = @(rewards) rewards.len() == 0 ? null : {
  flow = FLOW_HORIZONTAL
  gap = rewIconsGap
  children = arrayByRows(rewards, rewIconsPerRow)
    .map(@(row) {
        flow = FLOW_HORIZONTAL
        gap = rewIconsGap
        children = row.map(mkRewardIconComp)
    })
}

let function mkUnitPlate(unitInfo) {
  let { unit, startDelay } = unitInfo
  if (unit == null)
    return null
  let p = getUnitPresentation(unit)
  let { platoonUnits = [] } = unit
  let platoonSize = platoonUnits.len()
  let height = platoonSize == 0 ? unitPlateHeight
    : unitPlateHeight + platoonPlatesGap * platoonSize
  return {
    size = [ unitPlateWidth, height ]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkHighlight(startDelay, aUnitPlateFlareScale)
      {
        size = [ unitPlateWidth, height ]
        children = {
          size = [ unitPlateWidth, unitPlateHeight ]
          vplace = ALIGN_BOTTOM
          children = platoonSize > 0
            ? [
                mkPlatoonBgPlates(unit, platoonUnits)
                mkUnitBg(unit)
                mkUnitImage(unit)
                mkUnitTexts(unit, getPlatoonName(unit.name, loc))
                mkPlatoonPlateFrame()
              ]
            : [
                mkUnitBg(unit)
                mkUnitImage(unit)
                mkUnitTexts(unit, loc(p.locId))
              ]
        }
      }.__update(mkRewardAnimProps(startDelay, aUnitPlateSelfScale))
    ]
  }
}

let mkUnitRewards = @(unitsData) unitsData.len() == 0 ? null : @() {
  watch = serverConfigs
  flow = FLOW_VERTICAL
  gap = unitPlatesGap
  children =
    arrayByRows(
      unitsData.map(@(v)
        v.__merge({ unit = serverConfigs.value?.allUnits[v.id].__merge({ isUpgraded = v.gType == "unitUpgrade" }) })),
      unitsPerRow)
    .map(@(row) {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = unitPlatesGap
      children = row.map(mkUnitPlate)
    })
}

let bgGradWidth = hdpx(1200)
let bgGradLineHeight = hdpx(4)
let doubleSideGradBG = {
  size = [bgGradWidth, flex()]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, 0.45 * bgGradWidth]
  color = 0xA0000000
}
let doubleSideGradLine = doubleSideGradBG.__merge({
  size = [bgGradWidth, bgGradLineHeight]
  color = fadedTextColor
})
let bgGradientComp = {
  size = flex()
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    doubleSideGradLine
    doubleSideGradBG
    doubleSideGradLine
  ]

  transform = { pivot = [0.5, 0] }
  animations = [ { prop = AnimProp.scale, from = [1, 0], to = [1, 1],
    duration = aIntroTime,
    play = true, trigger = ANIM_SKIP } ]
}

let mkWndTitle = @(startDelay) {
  margin = [0, 0, hdpx(55), 0]
  rendObj = ROBJ_TEXT
  color = fadedTextColor
  text = loc("mainmenu/you_received")

  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0,
      duration = startDelay,
      play = true, trigger = ANIM_SKIP }
    { prop = AnimProp.opacity, from = 0, to = 1,
      delay = startDelay, duration = aTitleOpacityTime,
      play = true, trigger = ANIM_SKIP_DELAY }
    { prop = AnimProp.scale, from = [aTitleScaleMin, aTitleScaleMin], to = [aTitleScaleMin, aTitleScaleMin],
      duration = startDelay + aTitleScaleDelayTime,
      play = true, trigger = ANIM_SKIP }
    { prop = AnimProp.scale, from = [aTitleScaleMin, aTitleScaleMin], to = [aTitleScaleMax, aTitleScaleMax], easing = OutCubic,
      delay = startDelay + aTitleScaleDelayTime, duration = aTitleScaleUpTime,
      play = true, trigger = ANIM_SKIP }
    { prop = AnimProp.scale, from = [aTitleScaleMax, aTitleScaleMax], to = [1, 1], easing = InCubic,
      delay = startDelay + aTitleScaleDelayTime + aTitleScaleUpTime, duration = aTitleScaleDownTime,
      play = true, trigger = ANIM_SKIP, onFinish = @() isAnimFinished(true) }
  ]
}.__update(fontBig)

let mkTapToContinueText = @(startDelay) {
  rendObj = ROBJ_TEXT
  color = fadedTextColor
  text = loc("TapAnyToContinue")

  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0,
      duration = startDelay + aTitleScaleDelayTime + aTitleScaleUpTime,
      play = true, trigger = ANIM_SKIP }
    { prop = AnimProp.opacity, from = 0, to = 1,
      delay = startDelay + aTitleScaleDelayTime + aTitleScaleUpTime, duration = aTitleScaleDownTime,
      play = true, trigger = ANIM_SKIP_DELAY }
  ]
}.__update(fontMedium)

let function onCloseRequest() {
  if (!isAnimFinished.value) {
    isAnimFinished(true)
    anim_skip(ANIM_SKIP)
    anim_skip_delay(ANIM_SKIP_DELAY)
    return
  }
  // Setting the received unit as current
  let unitName = stackData.value?.unitPlates.findvalue(@(_) true)?.id
  let unit = myUnits.value?[unitName]
  if (unit != null) {
    setCurrentUnit(unit.name)
    requestOpenUnitPurchEffect(unit)
  }
  // Marking purchases as seen
  markPurchasesSeen(unseenPurchasesExt.value.keys())
}

let function mkMsgContent(stackDataV) {
  let { rewardIcons = [], unitPlates = [], outroDelay } = stackDataV
  let content = {
    size = [flex(), SIZE_TO_CONTENT]
    padding = [hdpx(28), 0, hdpx(38), 0]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = onCloseRequest
    flow = FLOW_VERTICAL
    gap = hdpx(44)
    children = [
      mkWndTitle(outroDelay)
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        gap = rewIconsRowToUnitPlatesGap
        children = [
          mkRewardIconsBlock(rewardIcons)
          mkUnitRewards(unitPlates)
        ]
      }
      mkTapToContinueText(outroDelay)
    ]
  }
  return makeVertScroll(content, { size = [flex(), SIZE_TO_CONTENT], maxHeight = maxWndHeight })
}

let messageWnd = {
  size = [wndWidth, SIZE_TO_CONTENT]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    bgGradientComp
    @() {
      watch = stackData
      size = [flex(), SIZE_TO_CONTENT]
      children = mkMsgContent(stackData.value)
    }
  ]
}

let showMessage = @() addModalWindow(bgShadedDark.__merge({
  key = WND_UID
  size = flex()
  onClick = onCloseRequest
  children = messageWnd
  animations = wndSwitchAnim
}))

if (needShow.value)
  showMessage()
needShow.subscribe(@(v) v ? showMessage() : close())
