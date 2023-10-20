from "%globalsDarg/darg_library.nut" import *
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { REWARD_STYLE_TINY, REWARD_SIZE_TINY, mkRewardPlate, mkRewardReceivedMark, mkRewardFixedIcon
} = require("%rGui/rewards/rewardPlateComp.nut")
let { premiumTextColor, hoverColor } = require("%rGui/style/stdColors.nut")
let { getLootboxName, getLootboxImageOriginal } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { mkCustomButton, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getLootboxRewardsViewInfo, isRewardReceived  } = require("%rGui/rewards/rewardViewInfo.nut")
let { CS_INCREASED_ICON, mkCurrencyImage, mkCurrencyText } = require("%rGui/components/currencyComp.nut")
let { showLootboxAds, eventRewards } = require("eventState.nut")
let { canShowAds } = require("%rGui/ads/adsState.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")


let REWARDS = 3
let bgColor = 0x80000000
let questBarColor = premiumTextColor
let barHeight = hdpx(10)
let btnSize = [hdpx(300), hdpx(90)]
let borderWidth = hdpx(1)
let fillColor = 0x70000000
let iconStyle = CS_INCREASED_ICON
let iconSize = iconStyle.iconSize
let lootboxHeight = hdpxi(320)
let rewardGap = REWARD_STYLE_TINY.boxGap
let tenRewards = " x 10"
let smallChestIconSize = hdpxi(40)

let lootboxInfoSize = [REWARD_SIZE_TINY * REWARDS + rewardGap * (REWARDS + 1),
  (REWARD_SIZE_TINY + rewardGap * 2) / 0.8]
let lootboxInfoSizeBig = [REWARD_SIZE_TINY * (REWARDS + 1) + rewardGap * (REWARDS + 2),
  (REWARD_SIZE_TINY + rewardGap * 2) / 0.8]

let SLIDE = 0.3
let OPACITY = 0.4

let hideAnimation = @(trigger) [
  {
    prop = AnimProp.opacity, from = 1.0, to = 1.0, duration = SLIDE, trigger
  }
  {
    prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = OPACITY,
    trigger, easing = InOutQuad
  }
]

let revealAnimation = @(trigger) [
  {
    prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = OPACITY,
    trigger, easing = InOutQuad
  }
]

let revealBtnsAnimation = [
  {
    prop = AnimProp.opacity, from = 0.0, to = 0.0, duration = SLIDE, play = true
  }
  {
    prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = OPACITY,
    play = true, delay = SLIDE, easing = InOutQuad
  }
]

let slideTransition = [
  { prop = AnimProp.translate, duration = SLIDE, easing = InOutQuad }
]

let infoCanvas = {
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor
  color = 0
  commands = [[VECTOR_POLY, 0, 0, 0, 80, 44, 80, 50, 100, 56, 80, 100, 80, 100, 0, 0, 0]]
  flow = FLOW_HORIZONTAL
  gap = rewardGap
  padding = [rewardGap, 0, 0, 0]
  halign = ALIGN_CENTER
}

let infoCanvasSmall = infoCanvas.__merge({ size = lootboxInfoSize })
let infoCanvasBig = infoCanvas.__merge({ size = lootboxInfoSizeBig })

let function lootboxInfo(lootbox = {}) {
  let rewardsPreview = Computed(function() {
    local rewards = []
    local slots = 0
    foreach (reward in getLootboxRewardsViewInfo(lootbox)) {
      if (slots + (reward?.slots ?? 0) > REWARDS + 1)
        continue
      slots += reward?.slots ?? 0
      rewards.append(reward)
      if (slots >= REWARDS)
        break
    }
    return { rewards, slots }
  })

  return @() {
    watch = [rewardsPreview, serverConfigs, servProfile]
    children = rewardsPreview.value.rewards.map(function(r) {
      let { rewardsCfg = null } = serverConfigs.value
      let id = r?.rewardId
      let showMark = id in rewardsCfg && isRewardReceived(lootbox, id, rewardsCfg[id], servProfile.value)
      return {
        children = [
          mkRewardPlate(r, REWARD_STYLE_TINY)
          showMark ? mkRewardReceivedMark(REWARD_STYLE_TINY) : null
          !showMark && r?.isFixed ? mkRewardFixedIcon(REWARD_STYLE_TINY) : null
        ]
      }
    })
  }.__update(rewardsPreview.value.slots > REWARDS ? infoCanvasBig : infoCanvasSmall)
}

let function progressBar(stepsFinished, stepsToNext, ovr = {}) {
  if (stepsToNext - stepsFinished <= 0)
    return { size = [btnSize[0], barHeight] }
  let questCompletion = stepsFinished.tofloat() / stepsToNext

  return {
    rendObj = ROBJ_BOX
    size = [btnSize[0], barHeight]
    fillColor = bgColor
    borderWidth
    borderColor = questBarColor
    children = [
      {
        rendObj = ROBJ_BOX
        size = [pw(100 * questCompletion), barHeight]
        fillColor = questBarColor
      }
    ]
  }.__update(ovr)
}

let function mkLootboxWndBtn(onClick, hasAdIcon, currencyId) {
  let stateFlags = Watched(0)

  return @() {
    watch = stateFlags
    size = btnSize
    rendObj = ROBJ_BOX
    sound = { click  = "meta_shop_buttons" }
    behavior = Behaviors.Button
    onClick
    borderWidth
    borderColor = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
    fillColor
    flow = FLOW_HORIZONTAL
    gap = iconSize / 2
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    onElemState = @(sf) stateFlags(sf)
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    children = [
      !hasAdIcon ? null
        : {
            size = [iconSize, iconSize]
            rendObj = ROBJ_IMAGE
            keepAspect = true
            image = Picture($"ui/gameuiskin#mp_spectator.avif:{iconSize}:{iconSize}:P")
          }
      mkCurrencyImage(currencyId, iconSize)
    ]
  }
}

let function mkLootboxImageWithTimer(name, blockSize, timeRange, sizeMul = 1.0) {
  let { start = 0, end = 0 } = timeRange
  let isActive = Computed(@() start < serverTime.value && (end <= 0 || end > serverTime.value))
  let timeText = Computed(@() start < serverTime.value ? ""
    : loc("lootbox/availableAfter", { time = secondsToHoursLoc(start - serverTime.value) }))

  return @() {
    watch = isActive
    size = [blockSize, lootboxHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        size = [(blockSize * sizeMul).tointeger(), (lootboxHeight * sizeMul).tointeger()]
        rendObj = ROBJ_IMAGE
        keepAspect = true
        image = getLootboxImageOriginal(name)
        picSaturate = isActive.value ? 1.0 : 0.2
        brightness = isActive.value ? 1.0 : 0.5
      }
      @() {
        watch = timeText
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        text = timeText.value
      }.__update(fontTiny)
    ]
  }
}

let function mkClickable(children, onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick
    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.9, 0.9]
      : (stateFlags.value & S_HOVER) != 0 ? [1.1, 1.1]
      : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = Linear }]
    sound = { click  = "click" }
    children
  }
}

let adsBtnContent = {
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FILL
      image = Picture($"ui/gameuiskin#mp_spectator.avif:{iconSize}:{iconSize}:P")
    }
    {
      maxWidth = hdpx(200)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = utf8ToUpper(loc("shop/watchAdvert/short"))
    }.__update(fontTinyAccentedShaded)
  ]
}

let mkAdsBtn = @(id) @() {
  watch = eventRewards
  children = mkCustomButton(
    adsBtnContent,
    @() showLootboxAds(id),
    canShowAds.value && eventRewards.value?[id].isReady ? buttonStyles.SECONDARY : buttonStyles.COMMON)
}

let mkCurrencyComp = @(value, currencyId) {
  size = [SIZE_TO_CONTENT, iconSize]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(20)
  children = [
    mkCurrencyImage(currencyId, iconSize)
    mkCurrencyText(value, iconStyle)
  ]
}

let function mkPurchaseBtns(lootbox, onPurchase) {
  let { name, price, currencyId, hasBulkPurchase = false, adRewardId = null, timeRange = 0 } = lootbox
  let { start = 0, end = 0 } = timeRange
  let isActive = Computed(@() start < serverTime.value && (end <= 0 || end > serverTime.value))

  return @() {
    watch = [isActive, balance]
    key = name
    flow = FLOW_HORIZONTAL
    gap = hdpx(40)
    animations = revealBtnsAnimation
    children = [
      adRewardId != null ? mkAdsBtn(adRewardId) : null
      textButtonPricePurchase(hasBulkPurchase ? utf8ToUpper(loc("events/oneReward")) : null,
        mkCurrencyComp(price, currencyId),
        @() onPurchase(lootbox, price, currencyId, loc(getLootboxName(name))),
        !isActive.value || (balance.value?[currencyId] ?? 0) < price ? buttonStyles.COMMON : null)
      !hasBulkPurchase ? null
        : textButtonPricePurchase(utf8ToUpper(loc("events/tenRewards")),
            mkCurrencyComp(price * 10, currencyId),
            @() onPurchase(lootbox, price * 10, currencyId, "".concat(loc(getLootboxName(name)), tenRewards), 10),
            !isActive.value || (balance.value?[currencyId] ?? 0) < price * 10 ? buttonStyles.COMMON : null)
    ]
  }
}

let mkSmokeBg = @(isVisible) @() !isVisible.value ? { watch = isVisible } : {
  watch = isVisible
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/event_bg.avif")
  keepAspect = KEEP_ASPECT_FILL
}

let smallChestIcon = {
  size = [smallChestIconSize, smallChestIconSize]
  margin = [0, hdpx(10)]
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"ui/gameuiskin#events_chest_icon.svg:{smallChestIconSize}:{smallChestIconSize}:P")
}

return {
  lootboxInfo
  lootboxInfoSize
  progressBar
  mkLootboxWndBtn
  mkLootboxImageWithTimer
  mkClickable
  mkPurchaseBtns
  mkSmokeBg

  smallChestIcon
  smallChestIconSize
  barHeight

  hideAnimation
  revealAnimation
  slideTransition
}
