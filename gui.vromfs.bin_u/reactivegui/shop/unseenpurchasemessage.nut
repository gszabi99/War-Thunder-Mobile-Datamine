from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { frnd } = require("dagor.random")
let { parse_json } = require("json")
let { doesLocTextExist } = require("dagor.localize")
let { arrayByRows, isEqual } = require("%sqstd/underscore.nut")
let { ComputedImmediate } = require("%sqstd/frp.nut")
let { rewardTypeByValue } = require("%appGlobals/rewardType.nut")
let { mkCurrencyFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { isInQueue } = require("%appGlobals/queueState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { activeUnseenPurchasesGroup, markPurchasesSeen, hasActiveCustomUnseenView,
  skipUnseenMessageAnimOnce, isUnseenGoodsVisible, unseenPurchaseUnitPlateKey
} = require("unseenPurchasesState.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { lootboxes, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curCampaignSlots, curSlots } = require("%appGlobals/pServer/slots.nut")
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { bgShadedDark } = require("%rGui/style/backgrounds.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { locColorTable } = require("%rGui/style/stdColors.nut")
let { getTextScaleToFitWidth, getFontToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { getUnitPresentation, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitInfo
} = require("%rGui/unit/components/unitPlateComp.nut")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { hasJustUnlockedUnitsAnimation } = require("%rGui/unit/justUnlockedUnits.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { tryResetToMainScene, canResetToMainScene } = require("%rGui/navState.nut")
let { lbCfgOrdered } = require("%rGui/leaderboard/lbConfig.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { getBattleModPresentation } = require("%appGlobals/config/battleModPresentation.nut")
let { mkBattleModEventUnitText } = require("%rGui/rewards/battleModComp.nut")
let { REWARD_STYLE_MEDIUM, getRewardPlateSize, rewardTicketDefaultSlots } = require("%rGui/rewards/rewardStyles.nut")
let { ignoreSubIdRTypes, getRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { mkRewardPlateBg, mkRewardPlateImage, mkProgressLabel, mkProgressBar, mkProgressBarText,
  mkRewardPlate, mkRewardUnitFlag
} = require("%rGui/rewards/rewardPlateComp.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { mkMsgConvert, mkMsgDiscount } = require("unseenPurchaseAddMessage.nut")
let { showPrizeSelectDelayed, ticketToShow } = require("%rGui/rewards/rewardPrizeSelect.nut")
let { getCurrencyBigIcon } = require("%appGlobals/config/currencyPresentation.nut")
let { mkLoootboxImage } = require("%appGlobals/config/lootboxPresentation.nut")
let { openSelectUnitToSlotWnd, canOpenSelectUnitWithModal } = require("%rGui/slotBar/slotBarState.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { unitInfoPanel, mkPlatoonOrUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { curUnitInProgress, enable_unit_skin } = require("%appGlobals/pServer/pServerApi.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { isDisabledGoods } = require("%rGui/shop/shopState.nut")
let { sendAppsFlyerSavedEvent } = require("%rGui/notifications/logEvents.nut")
let { mkGradText } =  require("%rGui/unitCustom/unitCustomComps.nut")


let wndWidth = saSize[0]
let contentPaddingX = hdpx(20)
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

let appsFlyerSaveId = "DefaultSkinWasReplaced"

let infoTextBySource = {
  premium_convert_by_subscription = @(count) loc("reward/premium_convert_by_subscription/desc",
    { time = secondsToHoursLoc(count) })
}

function defaultInfoText(id, paramInt) {
  let locId = $"reward/{id}/desc"
  return doesLocTextExist(locId) ? loc(locId, { count = paramInt }) : ""
}

let stackData = Computed(function() {
  let stackRaw = {}
  local convertions = []
  let lboxes = lootboxes.get()
  foreach (purch in activeUnseenPurchasesGroup.value.list) {
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

      if (!isUnseenGoodsVisible(data, purch.source, serverConfigs.get(), lboxes))
        continue

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
    currency = []
    premium = []
    item = []
    unitUpgrade = []
    unit = []
    decorator = []
    booster = []
    skin = []
    battleMod = []
    blueprint = []
    prizeTicket = []
    lootbox = []
    discount = []
  } = stacksSorted
  let rewardIcons = [].extend(lootbox, currency, premium, item, decorator, booster, skin, blueprint, prizeTicket)
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
    discounts = discount.filter(@(r) !isDisabledGoods(r))
  }.filter(@(v) v.len() != 0))
})

let needShow = keepref(ComputedImmediate(@() !hasActiveCustomUnseenView.value
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
needShow.subscribe(@(v) v ? isAnimFinished.set(false) : null)

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

function mkCommonCurrencyIcon(startDelay, curId, amount, scale = 1.0) {
  let size = round(rewIconSize * scale).tointeger()
  let fullId = mkCurrencyFullId(curId)
  let cfg = Computed(@() getCurrencyGoodsPresentation(fullId.get(), amount))
  return @() {
    watch = cfg
    size = [rewIconSize, rewIconSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkHighlight(startDelay, aRewardIconFlareScale)
      {
        size = [size, size]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{cfg.get()?.img}:{size}:{size}:K:P")
        fallbackImage = cfg.get()?.fallbackImg
            ? Picture($"ui/gameuiskin#{cfg.get().fallbackImg}:{size}:{size}:K:P")
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
      decoratorCompByType?[decoratorType.value](decoratorId)
        .__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
    ]
  }
}

let mkCustomCurrencyIcon = {
  gold = @(delay, id, _) mkRewardIcon(delay, getCurrencyBigIcon(id), 1.61, 1.8, 0.12, -0.05) 
  wp = @(delay, id, _) mkRewardIcon(delay, getCurrencyBigIcon(id), 1.61, 1.8, 0.12, -0.05)
  eventKey = @(delay, id, amount) mkCommonCurrencyIcon(delay, id, amount, 1.0)
}

let mkCurrencyIcon = @(delay, id, amount) mkCustomCurrencyIcon?[id](delay, id, amount)
  ?? mkCommonCurrencyIcon(delay, id, amount, 1.2)

let getTextLabelAnim = @(startDelay) [
  { prop = AnimProp.opacity, from = 0, to = 0,
    duration = startDelay + aRewardLabelDelay,
    play = true, trigger = ANIM_SKIP }
  { prop = AnimProp.opacity, from = 0, to = 1,
    delay = startDelay + aRewardLabelDelay, duration = aRewardLabelOpacityTime,
    play = true, trigger = ANIM_SKIP_DELAY }
]

function mkRewardLabel(startDelay, text) {
  let res = {
    rendObj = ROBJ_TEXT
    color = 0xFFFFFFFF
    text
    transform = {}
    animations = getTextLabelAnim(startDelay)
  }.__update(fontSmallShaded)
  let txtScale = getTextScaleToFitWidth(res, rewTextMaxWidth)
  if (txtScale < 1.0)
    res.__update({ transform = { scale = [txtScale, txtScale] } })
  return res
}

let mkPrizeTicketLabel = @(startDelay, text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = rewTextMaxWidth
  halign = ALIGN_CENTER
  color = 0xFFFFFFFF
  text
  transform = {}
  animations = getTextLabelAnim(startDelay)
}.__update(fontTinyAccented)

function mkRewardLabelMultiline(startDelay, text, ovr = {}) {
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
  return res.__update(getFontToFitWidth(res, rewTextMaxWidth * 2, [fontVeryTinyShaded, fontTinyShaded, fontMediumShaded]), ovr)
}

let mkDecoratorRewardLabel = @(startDelay, decoratorId)
  @() {
    watch = allDecorators
    children = mkRewardLabel(startDelay, loc($"decorator/{allDecorators.value?[decoratorId].dType}"))
  }

function mkSkinEquipButton(unitName, skinName) {
  let unit = Computed(@() campMyUnits.get()?[unitName])
  let currentSkin = Computed(@() unit.get()?.currentSkins[unitName] ?? "")

  return @() {
    watch = [currentSkin, unit]
    children = !unit.get() ? null
      : currentSkin.get() == skinName
        ? mkGradText(loc("skins/applied")).__update({ size = SIZE_TO_CONTENT, padding = hdpx(10) })
      : textButtonPrimary(loc("mainmenu/btnApply"),
          function() {
            enable_unit_skin(unitName, unitName, skinName)
            if (skinName != "")
              sendAppsFlyerSavedEvent("skin_equiped_1", appsFlyerSaveId)
          },
          { ovr = { size = [flex(), hdpx(70)] }, hasPattern = false })
  }
}

let skinIconSize = round(rewIconSize * 0.75).tointeger()
let skinIconBroderRadius = round(skinIconSize*0.2).tointeger()
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
        rendObj = ROBJ_BOX
        fillColor = 0xFFFFFFFF
        borderRadius = skinIconBroderRadius
        image = Picture($"ui/gameuiskin#{skinPresentation.image}:{skinIconSize}:{skinIconSize}:P")
      }.__update(mkRewardAnimProps(startDelay, aRewardIconSelfScale))
    ]
  }
}

function mkBlueprintPlateTexts(r, rStyle) {
  let { id } = r
  let available = Computed(@() servProfile.get()?.blueprints?[id] ?? 0)
  let total = Computed(@() serverConfigs.get()?.allBlueprints?[id].targetCount ?? 1)
  let unitRank = Computed(@() serverConfigs.value?.allUnits?[id]?.mRank)
  let hasBlueprintUnit = Computed(@() id in campMyUnits.get())

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
        padding = const [0, hdpx(5)]
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

  return @() {
    watch = unit
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
      unit.get() == null ? null : mkRewardUnitFlag(unit.get(), rStyle)
    ]
  }
}

function mkCustomIcon(rewardInfo, rStyle, ovr = {}) {
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
      mkRewardPlate(reward, rStyle.__merge(ovr))
    ]
  }
}

let mkPrizeTicketIcon = @(rewardInfo, rStyle) mkCustomIcon(rewardInfo, rStyle, { needShowPreview = false })
let mkDiscountIcon = @(rewardInfo, rStyle) mkCustomIcon(rewardInfo, rStyle)

let mkLootboxIcon = @(startDelay, id) mkCustomCurrencyIcon?[id](id, startDelay) ?? {
  size = [rewIconSize, rewIconSize]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    mkHighlight(startDelay, aRewardIconFlareScale)
    mkLoootboxImage(id, rewIconSize, 1, mkRewardAnimProps(startDelay, aRewardIconSelfScale))
  ]
}

let rewardCtors = {
  currency = {
    mkIcon = @(rewardInfo) mkCurrencyIcon(rewardInfo.startDelay, rewardInfo.id, rewardInfo.count)
    mkText = @(rewardInfo) mkRewardLabel(rewardInfo.startDelay, decimalFormat(rewardInfo.count))
  }
  premium = {
    mkIcon = @(rewardInfo) mkRewardIcon(rewardInfo.startDelay, "ui/gameuiskin#premium_active_big.avif", 1.43, 1.4)
    mkText = @(rewardInfo) mkRewardLabel(rewardInfo.startDelay,
      "".concat(rewardInfo.count, loc("measureUnits/days")))
  }
  item = {
    mkIcon = @(rewardInfo) mkCurrencyIcon(rewardInfo.startDelay, rewardInfo.id, rewardInfo.count)
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
    mkText = @(rewardInfo) {
      size = [rewTextMaxWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = hdpx(10)
      children = [
        mkRewardLabelMultiline(rewardInfo.startDelay, loc("skins/title", { unitName = loc(getUnitLocId(rewardInfo.id)) }))
        mkSkinEquipButton(rewardInfo.id, rewardInfo.subId)
      ]
    }
  }
  blueprint = {
    mkIcon = @(rewardInfo) mkBlueprintRewardIcon(rewardInfo, REWARD_STYLE_MEDIUM)
    mkText = @(rewardInfo) mkRewardLabelMultiline(rewardInfo.startDelay,
      "\n".concat(loc("blueprints/title", {count = rewardInfo.count}), loc(getUnitLocId(rewardInfo.id))))
  }
  prizeTicket = {
    mkIcon = @(rewardInfo) mkPrizeTicketIcon(rewardInfo, REWARD_STYLE_MEDIUM)
    function mkText(rewardInfo) {
      let { count } = rewardInfo
      let key = count > 1 ? "events/continueToChooseSome" : "events/continueToChoose"
      return mkPrizeTicketLabel(rewardInfo.startDelay, loc(key, { countPrize = count, count }))
    }
  }
  lootbox = {
    mkIcon = @(rewardInfo) mkLootboxIcon(rewardInfo.startDelay, rewardInfo.id)
    function mkText(rewardInfo) {
      let { count } = rewardInfo
      let key = count == 1 ? "events/continueToOpenOne" : "events/continueToOpenSeveral"
      return mkRewardLabel(rewardInfo.startDelay, loc(key, { count }))
    }
  }
  discount = {
    mkIcon = @(rewardInfo) mkDiscountIcon(rewardInfo, REWARD_STYLE_MEDIUM)
    mkText = @(rewardInfo) mkRewardLabelMultiline(rewardInfo.startDelay, loc("discounts/title"), fontSmall)
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
      {
        size = [rewBlockWidth, rewIconSize]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = mkIcon(rewardInfo)
      }
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
  let stateFlags = Watched(0)
  let key = unseenPurchaseUnitPlateKey(unitInfo.id)

  let p = getUnitPresentation(unit)
  return @(){
    key
    watch = stateFlags
    size = [ unitPlateWidth, unitPlateHeight ]
    behavior = Behaviors.Button
    onElemState = withTooltip(stateFlags, key, @() {
      content = unitInfoPanel({}, mkPlatoonOrUnitTitle, Watched(unit)),
      flow = FLOW_HORIZONTAL
    })
    onDetach = tooltipDetach(stateFlags)
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

function mkUnitButton(unitInfo, myUnits, cUnitInProgress, cSlots, cCampaignSlots) {
  if (unitInfo?.unit == null)
    return null
  let btnOvr = {ovr = { size = [unitPlateWidth, hdpx(70)], margin = const [hdpx(10),0,0,0]}, hasPattern = false}
  if (cCampaignSlots != null) {
    let onClick = @() openSelectUnitToSlotWnd(unitInfo.id, unseenPurchaseUnitPlateKey(unitInfo.id))
    return cSlots.findindex(@(slot) slot.name == unitInfo.id) == null
      ? textButtonPrimary(loc("mainmenu/btnEquip"), onClick, btnOvr)
      : textButtonCommon(loc("mainmenu/btnEquipped"), onClick, btnOvr)
  }

  return cUnitInProgress == null && unitInfo.id in myUnits && !myUnits[unitInfo.id].isCurrent
    ? textButtonPrimary(loc("mainmenu/btnEquip"), @() setCurrentUnit(unitInfo.id), btnOvr)
    : null
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
  watch = [serverConfigs, curSlots, campMyUnits, curUnitInProgress, curCampaignSlots, curCampaign]
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
      children = row.map(@(u) {
        flow = FLOW_VERTICAL
        children = [
          mkUnitPlate(u),
          u?.unit.campaign == curCampaign.get()
            ? mkUnitButton(u, campMyUnits.get(), curUnitInProgress.get(), curSlots.get(), curCampaignSlots.get())
            : null
        ]
      })
    })
}

let wndAnimations = [{
  prop = AnimProp.scale, from = [1, 0], to = [1, 1],
  duration = aIntroTime,
  play = true, trigger = ANIM_SKIP,
  onFinish = @() isAnimFinished.set(true)
}]

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
    play = true, trigger = ANIM_SKIP, onFinish = @() isAnimFinished.set(true) }
]

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
    margin = const [0, hdpx(150), 0, hdpx(150)]
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
    return modalWndHeader(loc("mainmenu/you_received"))

  return {
    margin = const [0, 0, hdpx(20), 0]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      modalWndHeader(loc("lb/rewardHeader"))
      { size = const [0, hdpx(30)] }
      mkLbInfoTable(texts)
      { size = const [0, hdpx(60)] }
      mkText(loc("mainmenu/you_received"))
    ]
    transform = {}
    animations = mkTitleAnimations(startDelay)
  }
}

function getCustomTexts(activeGroup) {
  let { sourcePostfix = "", list } = activeGroup
  let { source = "", paramInt = 0 } = list.findvalue(@(_) true)
  let id = sourcePostfix == "" ? source : source.slice(0, -sourcePostfix.len())
  let titleLocId = $"reward/{id}/title"
  return {
    title = doesLocTextExist(titleLocId) ? loc(titleLocId) : loc("mainmenu/you_received")
    infoText = id in infoTextBySource ? infoTextBySource[id](paramInt) : defaultInfoText(id, paramInt)
  }
}

function mkCustomTextRewardTitle(startDelay, activeGroup) {
  let { title, infoText } = getCustomTexts(activeGroup)
  if (infoText == "")
    return modalWndHeader(title)

  return {
    size = FLEX_H
    margin = const [0, 0, hdpx(20), 0]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      modalWndHeader(title)
      { size = const [0, hdpx(30)] }
      {
        size = FLEX_H
        padding = const [0, hdpx(30)]
        maxWidth = hdpx(1100)
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        color = textColor
        text = infoText
      }.__update(fontTinyAccented)
    ]
    transform = {}
    animations = mkTitleAnimations(startDelay)
  }
}

let titleCtors = {
  leaderboard = mkLeaderboardRewardTitle
  customTexts = mkCustomTextRewardTitle
}

let wndOvr = {
  leaderboard = { gap = hdpx(20) }
  customTexts = { gap = hdpx(20) }
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
  isAnimFinished.set(true)
  anim_skip(ANIM_SKIP)
  anim_skip_delay(ANIM_SKIP_DELAY)
}

function onCloseRequest() {
  if (!isAnimFinished.get()) {
    skipAnims()
    return
  }
  let unitId = stackData.get()?.unitPlates
    .filter(@(v) v?.id && (campMyUnits.get()?[v.id].isCurrent || curSlots.get().findvalue(@(slot) slot.name == v.id)))
    .findvalue(@(_) true)?.id
  let unit = campMyUnits.get()?[unitId]
  if (unit != null && canResetToMainScene()) {
    tryResetToMainScene()
    setHangarUnit(unitId)
    if (curCampaignSlots.get() != null)
      setCurrentUnit(unitId)
    requestOpenUnitPurchEffect(unit)
  }
  
  markPurchasesSeen(activeUnseenPurchasesGroup.value.list.keys())
}

function mkMsgContent(stackDataV, purchGroup, onClick) {
  let { rewardIcons = [], unitPlates = [], outroDelay, battleMod = [] } = stackDataV
  let { style = null } = purchGroup
  let title = titleCtors?[style](outroDelay, purchGroup) ?? modalWndHeader(loc("mainmenu/you_received"))
  let size = [
    max(
      min(unitPlates.len(), rewIconsPerRow) * unitPlateWidth,
      min(battleMod.len(), rewIconsPerRow) * unitPlateWidth,
      min(rewardIcons.len(), rewIconsPerRow) * rewBlockWidth
    ),
    SIZE_TO_CONTENT
  ]

  let content = {
    onAttach = @() canOpenSelectUnitWithModal.set(true)
    onDetach = @() canOpenSelectUnitWithModal.set(false)
    minWidth = hdpx(1100)
    padding = [0, contentPaddingX, hdpx(38), contentPaddingX]
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

let addRewardMessageWnd = @(onClick) modalWndBg.__merge({
  children = @() {
    watch = [stackData, activeUnseenPurchasesGroup]
    children = stackData.get()?.convertions != null
        ? mkMsgConvert(stackData.get().convertions, onClick)
      : stackData.get()?.discounts != null
        ? mkMsgDiscount(stackData.get().discounts, onClick)
      : null
  }
  animations = wndAnimations
})

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

let messageWnd = @(onClick) modalWndBg.__merge({
  children =  @() {
    watch = [stackData, activeUnseenPurchasesGroup]
    children = mkMsgContent(stackData.get(), activeUnseenPurchasesGroup.get(), onClick)
  }
  animations = wndAnimations
})

function onClick(){
  if (ticketToShow.get())
    showPrizeSelectDelayed()

  if ((stackData.get()?.convertions.len() ?? 0) > 0 || (stackData.get()?.discounts.len() ?? 0) > 0) {
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
  children = messageWnd(onClick)
  animations = wndSwitchAnim
  sound = { detach  = "meta_reward_window_close" }
}))

if (((stackData.get()?.convertions.len() ?? 0) > 0
  || (stackData.get()?.discounts.len() ?? 0) > 0)
    && (stackData.get()?.rewardIcons.len() ?? 0) == 0) {
  showAddRewardMessage()
  isAnimFinished.set(true)
}

stackData.subscribe(function(v) {
  if (((v?.convertions.len() ?? 0) > 0 || (v?.discounts.len() ?? 0) > 0) && (stackData.get()?.rewardIcons.len() ?? 0) == 0){
    showAddRewardMessage()
    isAnimFinished.set(true)
  }
  else
    removeModalWindow($"{WND_UID}_add")
})

if (needShow.value)
  showMessage()
needShow.subscribe(@(v) v ? showMessage() : close())
