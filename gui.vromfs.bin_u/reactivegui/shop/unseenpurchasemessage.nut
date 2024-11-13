from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { frnd } = require("dagor.random")
let { parse_json } = require("json")
let { arrayByRows, isEqual } = require("%sqstd/underscore.nut")
let { rewardTypeByValue } = require("%appGlobals/rewardType.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { isInQueue } = require("%appGlobals/queueState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { activeUnseenPurchasesGroup, markPurchasesSeen, hasActiveCustomUnseenView, skipUnseenMessageAnimOnce
} = require("unseenPurchasesState.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { bgShadedDark, bgHeader, bgMessage } = require("%rGui/style/backgrounds.nut")
let { locColorTable } = require("%rGui/style/stdColors.nut")
let { getTextScaleToFitWidth, getFontToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { getUnitPresentation, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitInfo, mkUnitFlag
} = require("%rGui/unit/components/unitPlateComp.nut")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { myUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { hasJustUnlockedUnitsAnimation } = require("%rGui/unit/justUnlockedUnits.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { tryResetToMainScene, canResetToMainScene } = require("%rGui/navState.nut")
let { lbCfgOrdered } = require("%rGui/leaderboard/lbConfig.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { eventSeason } = require("%rGui/event/eventState.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { getBattleModPresentation } = require("%appGlobals/config/battleModPresentation.nut")
let { mkBattleModEventUnitText } = require("%rGui/rewards/battleModComp.nut")
let { REWARD_STYLE_MEDIUM, getRewardPlateSize, rewardTicketDefaultSlots } = require("%rGui/rewards/rewardStyles.nut")
let { ignoreSubIdRTypes, getRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { mkRewardPlateBg, mkRewardPlateImage, mkProgressLabel, mkProgressBar, mkProgressBarText,
  mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { mkMsgConvertBlueprint } = require("unseenPurchaseAddMessage.nut")
let { showPrizeSelectDelayed, ticketToShow } = require("%rGui/rewards/rewardPrizeSelect.nut")
let { getCurrencyBigIcon } = require("%appGlobals/config/currencyPresentation.nut")


let bgGradient = bgMessage.__merge({size = flex()})
let wndWidth = saSize[0]
let maxWndHeight = saSize[1]
let rewBlockWidth = hdpx(340)
let rewBlocksVGap = hdpx(60)
let rewIconsPerRow = (wndWidth / rewBlockWidth).tointeger()
let rewIconSize = hdpxi(200)
let rewIconToTextGap = hdpx(29)
let rewTextMaxWidth = rewBlockWidth - hdpx(10)
let unitPlatesGap = hdpx(40)
let unitsPerRow = ((wndWidth + unitPlatesGap) / (unitPlateWidth + unitPlatesGap)).tointeger()

let textColor = 0xFFE0E0E0
let ANIM_SKIP = {}
let ANIM_SKIP_DELAY = {}

let aIntroTime = 0.2
let aRewardOpacityTime = 0.2
let aRewardScaleDelay = 0.05
let aRewardScaleUpTime = 0.05
let aRewardScaleDownTime = 0.23
let aRewardAnimTotalTime = aRewardScaleDelay + aRewardScaleUpTime + aRewardScaleDownTime
let aFlareDelay = 0.3
let aFlareUpTime = 0.2
let aFlareStayTime = 0.25
let aFlareDownTime = 0.2
let aFlareScaleMin = 0.1
let aFlareRotationSpeed = 500
let aFlareOpacityMax = 0.9
let aRewardIconSelfScale = 1.4
let aRewardIconFlareScale = 5.0
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

let stackData = Computed(function() {
  let stackRaw = {}
  local convertions = []
  foreach (purch in activeUnseenPurchasesGroup.value.list){
    convertions.extend(purch?.conversions ?? [])
    let conversionList = []
    foreach(c in purch?.conversions ?? [])
      conversionList.append(c.to, c.from)
    foreach (data in purch.goods) {
      let { id, gType, count, subId = ""} = data
      let rewId = gType in ignoreSubIdRTypes ? id : "".concat(id, subId)

      let convIdx = conversionList.findindex(@(c) isEqual(data, c))
      if (convIdx != null) {
        conversionList.remove(convIdx)
        continue
      }

      if (gType not in stackRaw)
        stackRaw[gType] <- {}
      if (rewId not in stackRaw[gType])
        stackRaw[gType][rewId] <- { id, gType, count, subId, order = -1 }
      else
        stackRaw[gType][rewId].count += count
    }
  }
  if (stackRaw?.unit != null && stackRaw?.unitUpgrade != null)
    stackRaw.unit = stackRaw.unit.filter(@(_, unitName) stackRaw.unitUpgrade?[unitName] == null)

  foreach (gType, _ in stackRaw)
    if (gType not in rewardTypeByValue)
      logerr($"Unknown reward goods type: {gType}")

  let stacksSorted = stackRaw.map(@(v) v.values())
  stacksSorted?.currency.each(@(v) v.order = orderByCurrency?[v.id] ?? orderByCurrency.len())
  stacksSorted?.item.each(@(v) v.order = orderByItems?[v.id] ?? orderByItems.len())
  foreach (arr in stacksSorted)
    arr.sort(@(a, b) a.order <=> b.order)

  let {
    currency = [],
    premium = [],
    item = [],
    unitUpgrade = [],
    unit = [],
    decorator = [],
    booster = [],
    skin = [],
    battleMod = []
    blueprint = []
    prizeTicket = []
  } = stacksSorted
  let rewardIcons = [].extend(currency, premium, item, decorator, booster, skin, blueprint, prizeTicket)
  let unitPlates = [].extend(unitUpgrade, unit)

  local lastIdx = -1
  unitPlates.each(@(v) v.idx <- ++lastIdx)
  battleMod.each(@(v) v.idx <- ++lastIdx)
  rewardIcons.each(@(v) v.idx <- ++lastIdx)

  let unitPlatesStartDelay = aIntroTime
  let bModeStartDelay = unitPlatesStartDelay + unitPlates.len() * aRewardAnimTotalTime
  let rewardIconsStartDelay = bModeStartDelay + battleMod.len() * aRewardAnimTotalTime
  let outroDelay = rewardIconsStartDelay + rewardIcons.len() * aRewardAnimTotalTime + aOutroExtraDelay

  unitPlates.each(@(v, i) v.startDelay <- unitPlatesStartDelay + (i * aRewardAnimTotalTime))
  battleMod.each(@(v, i) v.startDelay <- bModeStartDelay + (i * aRewardAnimTotalTime))
  rewardIcons.each(@(v, i) v.startDelay <- rewardIconsStartDelay + (i * aRewardAnimTotalTime))

  return {
    outroDelay
  }.__update({
    rewardIcons
    unitPlates
    battleMod
    convertions
  }.filter(@(v) v.len() != 0))
})

let needShow = keepref(Computed(@() !hasActiveCustomUnseenView.value
  && ((stackData.get()?.rewardIcons.len() ?? 0) > 0
    || (stackData.get()?.unitPlates.len() ?? 0) > 0
    || (stackData.get()?.battleMod.len() ?? 0) > 0)
  && activeUnseenPurchasesGroup.value.list.len() != 0
  && isInMenu.value
  && isLoggedIn.value
  && !isTutorialActive.value
  && !isInQueue.value
  && !hasJustUnlockedUnitsAnimation.value))

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

function mkHighlight(startDelay, sizeMul) {
  let highlightSize = (sizeMul * rewIconSize + 0.5).tointeger()
  let startRotation = frnd() * 360
  return {
    size = [highlightSize, highlightSize]
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture("ui/images/effects/searchlight_earth_flare.avif:0:P")
        opacity = 0

        transform = {}
        animations = [
          { prop = AnimProp.opacity, from = 0, to = 0,
            duration = startDelay + aFlareDelay
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.opacity, from = 0, to = aFlareOpacityMax,
            delay = startDelay + aFlareDelay, duration = aFlareUpTime,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.opacity, from = aFlareOpacityMax, to = aFlareOpacityMax,
            delay = startDelay + aFlareDelay + aFlareUpTime, duration = aFlareStayTime,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.opacity, from = aFlareOpacityMax, to = 0, easing = InCubic,
            delay = startDelay + aFlareDelay + aFlareUpTime + aFlareStayTime, duration = aFlareDownTime,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.scale, from = [aFlareScaleMin, aFlareScaleMin], to = [aFlareScaleMin, aFlareScaleMin],
            duration = startDelay + aFlareDelay,
            play = true, trigger = ANIM_SKIP }
          { prop = AnimProp.scale, from = [aFlareScaleMin, aFlareScaleMin], to = [1, 1],
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

function mkRewardIcon(startDelay, imgPath, aspectRatio = 1.0, sizeMul = 1.0, shiftX = 0.0, shiftY = 0.0) {
  let imgW = round(rewIconSize * sizeMul).tointeger()
  let imgH = round(imgW / aspectRatio).tointeger()
  return {
    size = [rewIconSize, rewIconSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkHighlight(startDelay, aRewardIconFlareScale)
      {
        size = [imgW, imgH]
        pos = [shiftX * imgW, shiftY * imgH]
        rendObj = ROBJ_IMAGE
        image = Picture($"{imgPath}:{imgW}:{imgH}:K:P")
        keepAspect = true
        color = 0xFFFFFFFF
      }.__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
    ]
  }
}

function mkDynamicRewardIcon(startDelay, curId, aspectRatio = 1.0, sizeMul = 1.0, shiftX = 0.0, shiftY = 0.0) {
  let imgW = round(rewIconSize * sizeMul).tointeger()
  let imgH = round(imgW / aspectRatio).tointeger()
  let cfg = Computed(@() getCurrencyGoodsPresentation(curId, eventSeason.get())?[0])
  return @() {
    watch = cfg
    size = [rewIconSize, rewIconSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkHighlight(startDelay, aRewardIconFlareScale)
      {
        size = [imgW, imgH]
        pos = [shiftX * imgW, shiftY * imgH]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{cfg.get()?.img}:{imgW}:{imgH}:K:P")
        fallbackImage = cfg.get()?.fallbackImg
            ? Picture($"ui/gameuiskin#{cfg.get()?.fallbackImg}:{imgW}:{imgH}:K:P")
          : null
        keepAspect = true
        color = 0xFFFFFFFF
      }.__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
    ]
  }
}

let mkTextDecoratorCtor = @(getText, font) function(decoratorId) {
  let textComp = {
    rendObj = ROBJ_TEXT
    halign = ALIGN_CENTER
    text = getText(decoratorId)
  }.__update(font)
  let txtScale = getTextScaleToFitWidth(textComp, rewTextMaxWidth)
  if (txtScale < 1.0)
    textComp.__update({ transform = { scale = [txtScale, txtScale] } })
  return {
    children = textComp
  }
}

let avatarIconSize = round(rewIconSize * 0.75).tointeger()
let mkImageDecoratorCtor = @(decoratorId) {
  size = [avatarIconSize, avatarIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"{getAvatarImage(decoratorId)}:{avatarIconSize}:{avatarIconSize}:P")
}

let decoratorCompByType = {
  nickFrame =  mkTextDecoratorCtor(@(id) frameNick("", id), fontVeryLarge)
  title     =  mkTextDecoratorCtor(@(id) loc($"title/{id}"), fontBig)
  avatar    =  mkImageDecoratorCtor
}

function mkDecoratorRewardIcon(startDelay, decoratorId) {
  let decoratorType = Computed(@() allDecorators.value?[decoratorId].dType)
  return @() {
    watch = decoratorType
    size = [SIZE_TO_CONTENT, rewIconSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkHighlight(startDelay, aRewardIconFlareScale)
      decoratorCompByType[decoratorType.value](decoratorId)
        .__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
    ]
  }
}

let mkCustomCurrencyIcon = {
  gold = @(id, startDelay) mkRewardIcon(startDelay, getCurrencyBigIcon(id), 1.61, 1.8, 0.12, -0.05)
  wp = @(id, startDelay) mkRewardIcon(startDelay, getCurrencyBigIcon(id), 1.61, 1.8, 0.12, -0.05)
  warbond = @(id, startDelay) mkDynamicRewardIcon(startDelay, id, 1.0, 1.2)
  eventKey = @(id, startDelay) mkDynamicRewardIcon(startDelay, id, 1.0, 1.0)
  nybond = @(id, startDelay) mkRewardIcon(startDelay, getCurrencyBigIcon(id), 1.0, 1.6)
  aprilbond = @(id, startDelay) mkRewardIcon(startDelay, getCurrencyBigIcon(id), 1.0, 1.6)
  halloweenbond = @(id, startDelay) mkRewardIcon(startDelay, getCurrencyBigIcon(id), 1.0, 1.6)
}

let mkCurrencyIcon = @(startDelay, id) mkCustomCurrencyIcon?[id](id, startDelay) ?? {
  size = [rewIconSize, rewIconSize]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    mkHighlight(startDelay, aRewardIconFlareScale)
    mkCurrencyImage(id, rewIconSize, mkRewardAnimProps(startDelay, aRewardIconSelfScale))
  ]
}

function mkRewardLabel(startDelay, text) {
  let res = {
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
  let txtScale = getTextScaleToFitWidth(res, rewTextMaxWidth)
  if (txtScale < 1.0)
    res.__update({ transform = { scale = [txtScale, txtScale] } })
  return res
}

function mkRewardLabelMultiline(startDelay, text) {
  let res = {
    size = [rewTextMaxWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text
    transform = { translate = [0, - rewIconToTextGap * 0.5] }
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 0,
        duration = startDelay + aRewardLabelDelay,
        play = true, trigger = ANIM_SKIP }
      { prop = AnimProp.opacity, from = 0, to = 1,
        delay = startDelay + aRewardLabelDelay, duration = aRewardLabelOpacityTime,
        play = true, trigger = ANIM_SKIP_DELAY }
    ]
  }.__update(fontMediumShaded)
  return res.__update(getFontToFitWidth(res, rewTextMaxWidth * 2, [fontVeryTinyShaded, fontTinyShaded, fontMediumShaded]))
}

let mkDecoratorRewardLabel = @(startDelay, decoratorId)
  @() {
    watch = allDecorators
    children = mkRewardLabel(startDelay, loc($"decorator/{allDecorators.value?[decoratorId].dType}"))
  }

let skinIconSize = round(rewIconSize * 0.75).tointeger()
function mkSkinRewardIcon(startDelay, unitName, skinName) {
  let skinPresentation = getSkinPresentation(unitName, skinName)
  return {
    size = [SIZE_TO_CONTENT, rewIconSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkHighlight(startDelay, aRewardIconFlareScale)
      {
        size = [skinIconSize, skinIconSize]
        rendObj = ROBJ_MASK
        image = Picture($"ui/gameuiskin#slot_mask.svg:{skinIconSize}:{skinIconSize}:P")
        children = {
          size = [skinIconSize, skinIconSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#{skinPresentation.image}:{skinIconSize}:{skinIconSize}:P")
        }
      }.__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
    ]
  }
}

function mkBlueprintPlateTexts(r, rStyle) {
  let { id } = r
  let available = Computed(@() servProfile.get()?.blueprints?[id] ?? 0)
  let total = Computed(@() serverConfigs.get()?.allBlueprints?[id].targetCount ?? 1)
  let unitRank = Computed(@() serverConfigs.value?.allUnits?[id]?.mRank)
  let hasBlueprintUnit = Computed(@() id in myUnits.get())

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
              mkProgressBar(available.get(), total.get())
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

function mkBlueprintRewardIcon(rewardInfo, rStyle) {
  let reward = getRewardsViewInfo([rewardInfo])?[0]
  let startDelay = rewardInfo.startDelay

  if (!reward)
    return mkRewardIcon(startDelay, $"ui/unitskin#blueprint_{rewardInfo.id}.avif", 1.0, 1.5)

  let size = getRewardPlateSize(reward.slots, rStyle)
  let unit = Computed(@() serverConfigs.get()?.allUnits?[rewardInfo.id])

  return {
    size
    children = [
      {
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = mkHighlight(startDelay, aRewardIconFlareScale)
      }.__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
      mkRewardPlateBg(reward, rStyle)
      mkRewardPlateImage(reward, rStyle)
      mkBlueprintPlateTexts(reward, rStyle)
      mkUnitFlag(unit.get(), rStyle)
    ]
  }
}

function mkPrizeTicketIcon(rewardInfo, rStyle) {
  let reward = getRewardsViewInfo([rewardInfo])?[0]
  let startDelay = rewardInfo.startDelay

  let size = getRewardPlateSize(rewardTicketDefaultSlots, rStyle)

  return {
    size
    halign = ALIGN_CENTER
    children = [
      {
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = mkHighlight(startDelay, aRewardIconFlareScale)
      }.__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
      mkRewardPlate({ label = loc("events/continueToChoose")}.__merge(reward),
        { needShowPreview = false }.__merge(rStyle))
    ]
  }
}

let rewardCtors = {
  currency = {
    mkIcon = @(rewardInfo) mkCurrencyIcon(rewardInfo.startDelay, rewardInfo.id)
    mkText = @(rewardInfo) mkRewardLabel(rewardInfo.startDelay, decimalFormat(rewardInfo.count))
  }
  premium = {
    mkIcon = @(rewardInfo) mkRewardIcon(rewardInfo.startDelay, "ui/gameuiskin#premium_active_big.avif", 1.43, 1.4)
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
  booster = {
    mkIcon = @(rewardInfo) mkRewardIcon(rewardInfo.startDelay, getBoosterIcon(rewardInfo.id))
    mkText = @(rewardInfo) mkRewardLabel(rewardInfo.startDelay, decimalFormat(rewardInfo.count))
  }
  skin = {
    mkIcon = @(rewardInfo) mkSkinRewardIcon(rewardInfo.startDelay, rewardInfo.id, rewardInfo.subId)
    mkText = @(rewardInfo) mkRewardLabelMultiline(rewardInfo.startDelay,
      loc("skins/title", { unitName = loc(getUnitLocId(rewardInfo.id)) }))
  }
  blueprint = {
    mkIcon = @(rewardInfo) mkBlueprintRewardIcon(rewardInfo, REWARD_STYLE_MEDIUM)
    mkText = @(rewardInfo) mkRewardLabelMultiline(rewardInfo.startDelay,
      "\n".concat(loc("blueprints/title", {count = rewardInfo.count}), loc(getUnitLocId(rewardInfo.id))))
  }
  prizeTicket = {
    mkIcon = @(rewardInfo) mkPrizeTicketIcon(rewardInfo, REWARD_STYLE_MEDIUM)
    mkText = @(rewardInfo) mkRewardLabel(rewardInfo.startDelay, loc("events/countPrizes",
      { countPrize = rewardInfo.count, count = rewardInfo.count }))
  }
}

function mkRewardIconComp(rewardInfo) {
  let { mkIcon, mkText } = rewardCtors[rewardInfo.gType]

  return {
    size = [rewBlockWidth, SIZE_TO_CONTENT]
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
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = rewBlocksVGap
  children = arrayByRows(rewards, rewIconsPerRow)
    .map(@(row) {
        flow = FLOW_HORIZONTAL
        children = row.map(mkRewardIconComp)
    })
}

function mkUnitPlate(unitInfo) {
  let { unit, startDelay } = unitInfo
  if (unit == null)
    return null
  let p = getUnitPresentation(unit)
  return {
    size = [ unitPlateWidth, unitPlateHeight ]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkHighlight(startDelay, aUnitPlateFlareScale)
      {
        size = [ unitPlateWidth, unitPlateHeight ]
        children = {
          size = [ unitPlateWidth, unitPlateHeight ]
          vplace = ALIGN_BOTTOM
          children = [
            mkUnitBg(unit)
            mkUnitImage(unit)
            mkUnitTexts(unit, loc(p.locId))
            mkUnitInfo(unit)
          ]
        }
      }.__update(mkRewardAnimProps(startDelay, aUnitPlateSelfScale))
    ]
  }
}

function mkBattleModEventUnitPlate(bmp, reward) {
  let unit = bmp.unitCtor()
  let { startDelay } = reward
  return {
    size = [ unitPlateWidth, unitPlateHeight ]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkHighlight(startDelay, aUnitPlateFlareScale)
      {
        size = [ unitPlateWidth, unitPlateHeight ]
        children = {
          size = [ unitPlateWidth, unitPlateHeight ]
          vplace = ALIGN_BOTTOM
          children = [
            mkUnitBg(unit)
            mkUnitImage(unit)
            mkBattleModEventUnitText(bmp, REWARD_STYLE_MEDIUM, 2)
          ]
        }
      }.__update(mkRewardAnimProps(startDelay, aUnitPlateSelfScale))
    ]
  }
}

function mkBattleModText(bmp, reward) {
  let { icon = null, locId = "unknown" } = bmp
  let { startDelay } = reward
  return {
    size = [rewBlockWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = rewIconToTextGap
    children = [
      {
        size = [rewIconSize, rewIconSize]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          mkHighlight(startDelay, aRewardIconFlareScale)
          icon == null ? null
            : {
                size = [rewIconSize, rewIconSize]
                rendObj = ROBJ_IMAGE
                image = Picture($"{icon}:{rewIconSize}:{rewIconSize}:P")
                keepAspect = true
              }
                .__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
        ]
      }
      mkRewardLabelMultiline(startDelay, loc(locId))
    ]
  }
}

let battleModeViewCtors = {
  eventUnit = mkBattleModEventUnitPlate
  common = mkBattleModText
}

let mkBattleModeRewards = @(rewards) rewards.len() == 0 ? null : @() {
  watch = serverConfigs
  flow = FLOW_VERTICAL
  gap = unitPlatesGap
  children = arrayByRows(
    rewards
      .map(function(v) {
        let bmp = getBattleModPresentation(v.id)
        if (bmp.viewType not in battleModeViewCtors)
          logerr($"Unknown battle mode reward view type: {v.id}")
        return battleModeViewCtors?[bmp.viewType]?(bmp, v)
      })
      .filter(@(v) v != null),
    unitsPerRow)
      .map(@(children) {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = unitPlatesGap
        children
      })
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

let bgGradientComp = bgGradient.__merge({
  animations = [ { prop = AnimProp.scale, from = [1, 0], to = [1, 1],
    duration = aIntroTime,
    play = true, trigger = ANIM_SKIP } ]
})

let mkTitleAnimations = @(startDelay) [
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

let wndTitle = bgHeader.__merge({
  size = [flex(), SIZE_TO_CONTENT]
  margin = [0, 0, hdpx(55), 0]
  padding = hdpx(15)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    color = textColor
    rendObj = ROBJ_TEXT
    text = loc("mainmenu/you_received")
  }.__update(fontBig)
})

let lbValueFields = ["tillPlaces", "place", "tillPercent", "percent"]
let LB_BIG = 100000000
function getLbRewardTexts(activeGroup) {
  let { sourcePrefix = "", list } = activeGroup
  let processed = {}
  let best = {}
  foreach(purch in list) {
    if (purch.source in processed)
      continue
    processed[purch.source] <- true
    let cfgList = parse_json(purch.source.slice(sourcePrefix.len()))
    if (type(cfgList) != "array") {
      logerr($"Wrong type of leaderboard reward source json (array required): {purch.source}")
      continue
    }

    foreach(cfg in cfgList) {
      let { mode = "" } = cfg
      if (mode not in best)
        best[mode] <- { mode }
      let modeBest = best[mode]

      foreach(key in lbValueFields) {
        local value = cfg?[key]
        if (type(value) == "array")
          value = value.reduce(@(a, b) b <= 0 ? a
            : a <= 0 ? b
            : min(a, b))
        if (type(value) != "float" && type(value) != "integer")
          continue
        if (key not in modeBest)
          modeBest[key] <- value
        else
          modeBest[key] = min(modeBest[key], value)
      }
    }
  }

  let ordered = best.values()
    .sort(@(a, b) (a?.tillPlaces ?? LB_BIG) <=> (b?.tillPlaces ?? LB_BIG)
      || (a?.tillPercent ?? LB_BIG) <=> (b?.tillPercent ?? LB_BIG)
      || (a?.place ?? LB_BIG) <=> (b?.place ?? LB_BIG))

  return ordered.map(function(modeBest) {
    let { mode, tillPlaces = -1, place = -1, tillPercent = -1 } = modeBest
    let locParams = { place = colorize("@mark", place), tillPercent = colorize("@mark", $"{tillPercent.tointeger()}%") }
    let hasPlaceReward = tillPlaces > 0 && place > 0
    let text = hasPlaceReward && tillPercent > 0 ? loc("lb/rewardHeader/placeAndPercent", locParams)
      : tillPercent > 0 && tillPercent < 100 ? loc("lb/rewardHeader/tillPercent", locParams)
      : place > 0 ? loc("lb/rewardHeader/place", locParams)
      : ""
    let modeName = loc(lbCfgOrdered.findvalue(@(lb) lb.gameMode == mode)?.locId ?? $"lb/{mode}")
    return { modeName, text }
  })
}

let mkText = @(text, style = {}) {
  rendObj = ROBJ_TEXT
  color = textColor
  text
}.__update(fontTinyAccented, style)

let mkTextArea = @(text, style = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = textColor
  colorTable = locColorTable
  text
}.__update(fontTinyAccented, style)

function mkLbInfoTable(texts) {
  let comps = texts.map(@(data) {
    modeName = mkTextArea($"{data.modeName}{colon}", { color = locColorTable.mark })
    text = mkTextArea(data.text)
  })

  let sizes = { modeName = 0, text = 0 }
  foreach(data in comps)
    foreach(key, comp in data)
      sizes[key] = max(sizes[key], calc_comp_size(comp)[0])

  return {
    margin = [0, hdpx(150), 0, hdpx(150)]
    flow = FLOW_VERTICAL
    children = comps.map(@(data) {
      gap = hdpx(40)
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        {
          size = [sizes.modeName, SIZE_TO_CONTENT]
          children = data.modeName
        }
        {
          size = [sizes.text, SIZE_TO_CONTENT]
          halign = ALIGN_RIGHT
          children = data.text
        }
      ]
    })
  }
}

function mkLeaderboardRewardTitle(startDelay, activeGroup) {
  let texts = getLbRewardTexts(activeGroup)
  if (texts.len() == 0)
    return wndTitle

  return {
    margin = [0, 0, hdpx(20), 0]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      bgHeader.__merge({
        padding = [hdpx(15), hdpx(100)]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = mkText(loc("lb/rewardHeader"), fontSmall)
      })
      { size = [0, hdpx(30)] }
      mkLbInfoTable(texts)
      { size = [0, hdpx(60)] }
      mkText(loc("mainmenu/you_received"))
    ]
    transform = {}
    animations = mkTitleAnimations(startDelay)
  }
}

let titleCtors = {
  leaderboard = mkLeaderboardRewardTitle
}

let wndOvr = {
  leaderboard = { gap = hdpx(20) }
}

let mkTapToContinueText = @(startDelay) {
  rendObj = ROBJ_TEXT
  color = textColor
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

function skipAnims() {
  isAnimFinished(true)
  anim_skip(ANIM_SKIP)
  anim_skip_delay(ANIM_SKIP_DELAY)
}

function onCloseRequest() {
  if (!isAnimFinished.value) {
    skipAnims()
    return
  }
  // Setting the received unit as current
  let unitId = stackData.value?.unitPlates.findvalue(@(_) true)?.id
  let unit = myUnits.value?[unitId]
  if (unit != null && canResetToMainScene()) {
    let errString = unitId == curUnit.get()?.name ? "" : setCurrentUnit(unitId)
    if (errString == "") {
      tryResetToMainScene()
      setHangarUnit(unitId)
      requestOpenUnitPurchEffect(unit)
    }
  }
  // Marking purchases as seen
  markPurchasesSeen(activeUnseenPurchasesGroup.value.list.keys())
}

function mkMsgContent(stackDataV, purchGroup, onClick) {
  let { rewardIcons = [], unitPlates = [], outroDelay, battleMod = [] } = stackDataV
  let { style = null } = purchGroup
  let title = titleCtors?[style](outroDelay, purchGroup) ?? wndTitle
  let size = [
    max(
      unitPlates.len() * unitPlateWidth,
      battleMod.len() * unitPlateWidth,
      min(rewardIcons.len(), rewIconsPerRow) * rewBlockWidth
    ) + hdpx(300),
    SIZE_TO_CONTENT
  ]
  let content = {
    minWidth = hdpx(900)
    padding = [0, 0, hdpx(38), 0]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    flow = FLOW_VERTICAL
    gap = hdpx(44)
    sound = {
      attach = (unitPlates.len() > 0 || battleMod.len() > 0
        ? "meta_daily_reward"
        : "meta_unlock_unit")
    }
    children = [
      title
      {
        size
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        gap = rewBlocksVGap
        children = [
          mkUnitRewards(unitPlates)
          mkBattleModeRewards(battleMod)
          mkRewardIconsBlock(rewardIcons)
        ]
      }
      mkTapToContinueText(outroDelay)
    ]
  }.__update(wndOvr?[style] ?? {})
  return makeVertScroll(content, { size = SIZE_TO_CONTENT maxHeight = maxWndHeight })
}

let addRewardMessageWnd = @(onClick){
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    bgGradientComp
    @() {
      watch = [stackData, activeUnseenPurchasesGroup]
      children = mkMsgConvertBlueprint(stackData.get()?.convertions, onClick)
    }
  ]
}

let showAddRewardMessage = @() addModalWindow(bgShadedDark.__merge({
  key = $"{WND_UID}_add"
  size = flex()
  function onAttach() {
    if (!skipUnseenMessageAnimOnce.value)
      return
    skipUnseenMessageAnimOnce(false)
    skipAnims()
  }
  onClick = onCloseRequest
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = @() addRewardMessageWnd(onCloseRequest)
  animations = wndSwitchAnim
  sound = { detach  = "meta_reward_window_close" }
}))

let messageWnd = @(onClick){
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    bgGradientComp
    @() {
      watch = [stackData, activeUnseenPurchasesGroup]
      children = mkMsgContent(stackData.get(), activeUnseenPurchasesGroup.get(), onClick)
    }
  ]
}

function onClick(){
  if (ticketToShow.get())
    showPrizeSelectDelayed()

  if ((stackData.get()?.convertions.len() ?? 0) > 0) {
    close()
    showAddRewardMessage()
  }
  else
    onCloseRequest()
}

let showMessage = @() addModalWindow(bgShadedDark.__merge({
  key = WND_UID
  size = flex()
  function onAttach() {
    if (!skipUnseenMessageAnimOnce.value)
      return
    skipUnseenMessageAnimOnce(false)
    skipAnims()
  }
  onClick
  children = @() messageWnd(onClick)
  animations = wndSwitchAnim
  sound = { detach  = "meta_reward_window_close" }
}))

if((stackData.get()?.convertions.len()?? 0) > 0
  && (stackData.get()?.rewardIcons.len() ?? 0) == 0){
  showAddRewardMessage()
  isAnimFinished(true)
}

stackData.subscribe(function(v) {
  if((v?.convertions.len() ?? 0) > 0 && (stackData.get()?.rewardIcons.len() ?? 0) == 0){
    showAddRewardMessage()
    isAnimFinished(true)
  }
  else
    removeModalWindow($"{WND_UID}_add")
})

if (needShow.value)
  showMessage()
needShow.subscribe(@(v) v ? showMessage() : close())
