from "%globalsDarg/darg_library.nut" import *
let { REWARD_STYLE_SMALL, REWARD_SIZE_SMALL, mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { premiumTextColor, hoverColor } = require("%rGui/style/stdColors.nut")
let { getLootboxImage, getLootboxName } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { mkCustomButton, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { mkCurrencyComp, CS_VERY_BIG, mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { showLootboxAds, eventRewards } = require("eventState.nut")
let { canShowAds } = require("%rGui/ads/adsState.nut")
let { balanceEventKey, EVENT_KEY } = require("%appGlobals/currenciesState.nut")


let REWARDS = 3
let bgColor = 0x80000000
let questBarColor = premiumTextColor
let barHeight = hdpx(10)
let btnSize = [hdpx(300), hdpx(90)]
let borderWidth = hdpx(1)
let fillColor = 0x70000000
let iconSize = hdpxi(70)
let lootboxMaxSize = hdpxi(320)
let rewardGap = hdpx(20)
let tenRewards = " x 10"

let lootboxInfoSize = [REWARD_SIZE_SMALL * REWARDS + rewardGap * (REWARDS + 1),
  (REWARD_SIZE_SMALL + rewardGap * 2) / 0.8]

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
  size = lootboxInfoSize
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor
  color = 0
  commands = [[VECTOR_POLY, 0, 0, 0, 80, 44, 80, 50, 100, 56, 80, 100, 80, 100, 0, 0, 0]]
  flow = FLOW_HORIZONTAL
  gap = rewardGap
  padding = [rewardGap, 0, 0, 0]
  halign = ALIGN_CENTER
}

let function lootboxInfo(rewards = {}) {
  let rewardsPreview = Computed(function() {
    local res = []
    local slots = 0
    foreach (id, _ in rewards) {
      let reward = getRewardsViewInfo(campConfigs.value?.rewardsCfg[id])
      if (slots + (reward?[0].slots ?? 0) > REWARDS)
        continue
      slots += reward?[0].slots ?? 0
      res.extend(reward)
    }
    return res.sort(sortRewardsViewInfo)
  })

  return @() {
    watch = rewardsPreview
    children = rewardsPreview.value.map(@(r) mkRewardPlate(r, REWARD_STYLE_SMALL))
  }.__update(infoCanvas)
}

let function progressBar(stepsFinished, stepsTotal, ovr = {}) {
  if (!stepsFinished || !stepsTotal)
    return { size = [btnSize[0], barHeight] }.__update(ovr)

  let questCompletion = stepsFinished.tofloat() / stepsTotal

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

let function mkLootboxImage(name, imgSize) {
  imgSize = imgSize ?? lootboxMaxSize

  return {
    size = [lootboxMaxSize, lootboxMaxSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = [imgSize, imgSize]
      rendObj = ROBJ_IMAGE
      keepAspect = true
      image = getLootboxImage(name, imgSize)
    }
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

let function mkPurchaseBtns(lootbox, onPurchase) {
  let { name, price, currencyId, hasBulkPurchase = false, adRewardId = null } = lootbox

  return @() {
    watch = balanceEventKey
    flow = FLOW_HORIZONTAL
    gap = hdpx(40)
    animations = revealBtnsAnimation
    children = [
      adRewardId != null ? mkAdsBtn(adRewardId) : null
      textButtonPricePurchase(hasBulkPurchase ? utf8ToUpper(loc("events/oneReward")) : null,
        mkCurrencyComp(price, currencyId, CS_VERY_BIG),
        @() onPurchase(name, price, currencyId, loc(getLootboxName(name))),
        currencyId == EVENT_KEY && balanceEventKey.value < price ? buttonStyles.COMMON : null)
      !hasBulkPurchase ? null
        : textButtonPricePurchase(utf8ToUpper(loc("events/tenRewards")),
            mkCurrencyComp(price * 10, currencyId, CS_VERY_BIG),
            @() onPurchase(name, price * 10, currencyId, "".concat(loc(getLootboxName(name)), tenRewards), 10))
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

return {
  lootboxInfo
  progressBar
  mkLootboxWndBtn
  mkLootboxImage
  mkPurchaseBtns
  mkSmokeBg

  hideAnimation
  revealAnimation
  slideTransition
}