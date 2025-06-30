from "%globalsDarg/darg_library.nut" import *
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { G_LOOTBOX } = require("%appGlobals/rewardType.nut")
let { mkCurrencyFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { REWARD_STYLE_TINY, mkRewardPlate, mkRewardFixedIcon
} = require("%rGui/rewards/rewardPlateComp.nut")
let { mkCustomButton, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getLootboxRewardsViewInfo, canReceiveFixedReward, isRewardEmpty, NO_DROP_LIMIT
} = require("%rGui/rewards/rewardViewInfo.nut")
let { CS_INCREASED_ICON, mkCurrencyImage, mkCurrencyText } = require("%rGui/components/currencyComp.nut")
let { bestCampLevel, eventSeason, curEvent } = require("eventState.nut")
let { adsButtonCounter, isProviderInited } = require("%rGui/ads/adsState.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { openLbWnd } = require("%rGui/leaderboard/lbState.nut")
let { openEventQuestsWnd } = require("%rGui/quests/questsState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { schRewards, onSchRewardReceive, adBudget } = require("%rGui/shop/schRewardsState.nut")
let { getLootboxImage, lootboxFallbackPicture } = require("%appGlobals/config/lootboxPresentation.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")
let { getStepsToNextFixed } = require("%rGui/shop/lootboxPreviewState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let REWARDS = 3
let fillColor = 0x70000000
let hoverColor = 0xA0000000
let iconStyle = CS_INCREASED_ICON
let iconSize = iconStyle.iconSize
let lootboxHeight = hdpxi(320)
let rewardGap = REWARD_STYLE_TINY.boxGap
let vipIconW = CS_INCREASED_ICON.iconSize
let vipIconH = (CS_INCREASED_ICON.iconSize / 1.3).tointeger()

let rewardsSize = REWARD_STYLE_TINY.boxSize
let lootboxInfoSize = [rewardsSize * REWARDS + rewardGap * (REWARDS + 1),
  (rewardsSize + rewardGap * 2) / 0.8]
let lootboxInfoSizeBig = [rewardsSize * (REWARDS + 1) + rewardGap * (REWARDS + 2),
  (rewardsSize + rewardGap * 2) / 0.8]

let aTimeOpacity = 0.4
let revealBtnsAnimation = [
  {
    prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = aTimeOpacity,
    play = true, easing = InOutQuad
  }
]

let infoCanvas = {
  rendObj = ROBJ_VECTOR_CANVAS
  color = 0
  commands = [[VECTOR_POLY, 0, 0, 0, 80, 44, 80, 50, 100, 56, 80, 100, 80, 100, 0, 0, 0]]
  flow = FLOW_HORIZONTAL
  gap = rewardGap
  padding = [rewardGap, 0, 0, 0]
  halign = ALIGN_CENTER
}

let infoCanvasSmall = infoCanvas.__merge({ size = lootboxInfoSize })
let infoCanvasBig = infoCanvas.__merge({ size = lootboxInfoSizeBig })

function canReceiveLastReward(lootbox, reward, profile) {
  if (!(reward?.isJackpot || reward?.isFixed))
    return true
  let { name, fixedRewards } = lootbox
  let openCount = profile?.lootboxStats[name].opened ?? 0
  return null != fixedRewards.findindex(@(_, idxStr) idxStr.tointeger() > openCount)
}

function isDropLimitReached(reward, profile) {
  let { dropLimitRaw = NO_DROP_LIMIT, source, rewardId } = reward
  return dropLimitRaw != NO_DROP_LIMIT && dropLimitRaw <= (profile?.lootboxStats[source].total?[rewardId] ?? 0)
}

let lootboxInfo = @(lootbox, stateFlags) function() {
  local rewards = []
  local slots = 0
  let allRewards = getLootboxRewardsViewInfo(lootbox)
  let profile = servProfile.get()
  foreach (reward in allRewards) {
    if ((reward?.isLastReward && (rewards.len() != 0 || !canReceiveLastReward(lootbox, reward, profile)))
        || slots + (reward?.slots ?? 0) > REWARDS + 1
        || isRewardEmpty(reward.rewardCfg, profile)
        || isDropLimitReached(reward, profile)
        || ((reward?.isJackpot || reward?.isFixed)
          && !canReceiveFixedReward(lootbox, reward?.parentRewardId ?? reward.rewardId, reward.rewardCfg, profile))
        )
      continue
    slots += reward?.slots ?? 0
    rewards.append(reward)
    if (slots >= REWARDS)
      break
  }

  let children = rewards.map(@(r) {
    children = [
      mkRewardPlate(r, REWARD_STYLE_TINY),
      (r?.isFixed || r?.isJackpot) ? mkRewardFixedIcon(REWARD_STYLE_TINY) : null
    ]
  })

  return {
    watch = servProfile
    children = @() {
      watch = stateFlags
      fillColor = stateFlags.get() & S_HOVER ? hoverColor : fillColor
      children
      transitions = [{ prop = AnimProp.fillColor, duration = 0.15, easing = Linear }]
    }.__update(slots > REWARDS ? infoCanvasBig : infoCanvasSmall)
  }
}

let mkEventLoootboxImage = @(id, size = null, ovr = {}) @() {
  watch = eventSeason
  size = size ? [size, size] : SIZE_TO_CONTENT
  rendObj = ROBJ_IMAGE
  image = getLootboxImage(id, eventSeason.get(), size)
  fallbackImage = lootboxFallbackPicture
  keepAspect = true
}.__update(ovr)

function mkLootboxImageWithTimer(name, width, timeRange, reqPlayerLevel, sizeMul = 1.0) {
  let imageSize = [width, lootboxHeight].map(@(v) (v * sizeMul + 0.5).tointeger())
  let blockSize = [width, lootboxHeight]
  let { start = 0, end = 0 } = timeRange
  let isActive = Computed(@() bestCampLevel.value >= reqPlayerLevel
    && start < serverTime.value
    && (end <= 0 || end > serverTime.value))
  let timeText = Computed(@() bestCampLevel.value < reqPlayerLevel
      ? loc("lootbox/reqCampaignLevel", { reqLevel = reqPlayerLevel })
    : start > serverTime.value
      ? loc("lootbox/availableAfter", { time = secondsToHoursLoc(start - serverTime.value) })
    : "")

  return @() {
    watch = isActive
    size = blockSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkEventLoootboxImage(name, null,
        {
          size = imageSize
          picSaturate = isActive.value ? 1.0 : 0.2
          brightness = isActive.value ? 1.0 : 0.5
        })
      @() {
        watch = timeText
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        text = timeText.value
      }.__update(fontTiny)
    ]
  }
}

let mkBtnContent = @(img, text, ovr = {}) {
  key = text
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    !img ? null : {
      size = !hasVip.get() ? [iconSize, iconSize] : [vipIconW, vipIconH]
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FILL
      image = !hasVip.get()
        ? Picture($"{img}:{iconSize}:{iconSize}:P")
        : Picture($"{img}:{vipIconW}:{vipIconH}:P")
    }
    {
      maxWidth = hdpx(250)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = utf8ToUpper(text)
    }.__update(fontTinyAccentedShaded)
  ]
}.__update(ovr)

function mkAdsBtn(reqPlayerLevel, adReward) {
  let { cost = 0 } = adReward
  return @() {
    watch = [bestCampLevel, adBudget, isProviderInited]
    children = mkCustomButton(
      cost >= adBudget.get() ? mkBtnContent(null, loc("btn/adsLimitReached"))
        : !hasVip.get()
          ? mkBtnContent("ui/gameuiskin#watch_ads.svg", loc("shop/watchAdvert/short"), adsButtonCounter)
        : mkBtnContent("ui/gameuiskin#gamercard_subs_vip.svg", loc("shop/vip/budget_rewards", { num = adBudget.get() }), adsButtonCounter),
      @() bestCampLevel.value >= reqPlayerLevel
          ? onSchRewardReceive(adReward)
        : openMsgBox({ text = loc("lootbox/availableAfterLevel", { level = colorize("@mark", reqPlayerLevel) }) }),
      (!isProviderInited.get()
        || (bestCampLevel.value >= reqPlayerLevel
          && adReward?.isReady
          && (cost < adBudget.value))
              ? buttonStyles.SECONDARY
            : buttonStyles.COMMON)
        .__merge({ hotkeys = ["^J:RB"] }))
  }
}

let leaderbordBtn = mkCustomButton(
  mkBtnContent("ui/gameuiskin#prizes_icon.svg", loc("mainmenu/titleLeaderboards")),
  openLbWnd,
  buttonStyles.PRIMARY.__merge({ hotkeys = ["^J:X"] }))

let questsBtn = mkCustomButton(
  mkBtnContent("ui/gameuiskin#quests.svg", loc("mainmenu/btnQuests")),
  @() openEventQuestsWnd(curEvent.get()),
  buttonStyles.PRIMARY.__merge({ hotkeys = ["^J:Y"] }))

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

function mkPurchaseBtns(lootbox, onPurchase) {
  let { name, price, currencyId, hasBulkPurchase = false, timeRange = null, reqPlayerLevel = 0 } = lootbox
  let currencyFullId = mkCurrencyFullId(currencyId)
  let { start = 0, end = 0 } = timeRange
  let isActive = Computed(@() bestCampLevel.value >= reqPlayerLevel
    && start < serverTime.value
    && (end <= 0 || end > serverTime.value))
  let adReward = Computed(@() schRewards.value.findvalue(
    @(r) (null != r.rewards.findvalue(@(g) g.id == name && g.gType == G_LOOTBOX))))
  let canOpenX10 = Computed(function(){
    let stepsToFixed = getStepsToNextFixed(lootbox, serverConfigs.get(), servProfile.get())
    if(stepsToFixed[1] == 0)
      return true
    if(stepsToFixed[1] - stepsToFixed[0] <= 10)
      return false
    return true
  })

  return @() {
    watch = [isActive, balance, adReward, currencyFullId, canOpenX10]
    key = name
    flow = FLOW_HORIZONTAL
    gap = hdpx(40)
    animations = revealBtnsAnimation
    children = [
      adReward.value != null ? mkAdsBtn(reqPlayerLevel, adReward.value) : null
      textButtonPricePurchase(hasBulkPurchase ? utf8ToUpper(loc("events/oneReward")) : null,
        mkCurrencyComp(price, currencyFullId.get()),
        @() onPurchase(lootbox, price, currencyFullId.get()),
        (!isActive.value || (balance.value?[currencyFullId.get()] ?? 0) < price ? buttonStyles.COMMON : {})
          .__merge({ hotkeys = ["^J:X"] }))
      !hasBulkPurchase ? null
        : textButtonPricePurchase(utf8ToUpper(loc("events/tenRewards")),
            mkCurrencyComp(price * 10, currencyFullId.get()),
            @() !canOpenX10.get() ? null : onPurchase(lootbox, price * 10, currencyFullId.get(), 10),
            (!isActive.value || (balance.value?[currencyFullId.get()] ?? 0) < price * 10
              || !canOpenX10.get() ? buttonStyles.COMMON : {})
              .__merge({ hotkeys = ["^J:Y"], tooltipCtor = @() !canOpenX10.get() ? loc("x10Btn/desc") : null,
                repayTime = 0 }))
    ]
  }
}

return {
  lootboxInfo
  mkLootboxImageWithTimer
  lootboxHeight
  mkPurchaseBtns

  leaderbordBtn
  questsBtn
}
