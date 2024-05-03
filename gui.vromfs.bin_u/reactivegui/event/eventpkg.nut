from "%globalsDarg/darg_library.nut" import *
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { G_LOOTBOX } = require("%appGlobals/rewardType.nut")
let { REWARD_STYLE_TINY, mkRewardPlate, mkRewardReceivedMark, mkRewardFixedIcon
} = require("%rGui/rewards/rewardPlateComp.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { mkLoootboxImage } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { mkCustomButton, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getLootboxRewardsViewInfo, isRewardReceived  } = require("%rGui/rewards/rewardViewInfo.nut")
let { CS_INCREASED_ICON, mkCurrencyImage, mkCurrencyText } = require("%rGui/components/currencyComp.nut")
let { bestCampLevel } = require("eventState.nut")
let { canShowAds, adsButtonCounter } = require("%rGui/ads/adsState.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { openLbWnd } = require("%rGui/leaderboard/lbState.nut")
let { openEventQuestsWnd } = require("%rGui/quests/questsState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { schRewards, onSchRewardReceive, adBudget } = require("%rGui/shop/schRewardsState.nut")


let REWARDS = 3
let bgColor = 0x80000000
let questBarColor = premiumTextColor
let barHeight = hdpx(10)
let borderWidth = hdpx(1)
let fillColor = 0x70000000
let hoverColor = 0xA0000000
let iconStyle = CS_INCREASED_ICON
let iconSize = iconStyle.iconSize
let lootboxHeight = hdpxi(320)
let rewardGap = REWARD_STYLE_TINY.boxGap
let smallChestIconSize = hdpxi(40)

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

let christmas2023 = {
  img = "ui/images/event_christmas_boxes.avif:0:P"
  sizeMul = 2.0
}
let customLootboxCfg = {
  event_special_ships_christmas_2023 = christmas2023
  event_special_tanks_christmas_2023 = christmas2023
}

function lootboxInfo(lootbox, sf) {
  local rewards = []
  local slots = 0
  foreach (reward in getLootboxRewardsViewInfo(lootbox)) {
    if (reward?.isLastReward || slots + (reward?.slots ?? 0) > REWARDS + 1)
      continue
    slots += reward?.slots ?? 0
    rewards.append(reward)
    if (slots >= REWARDS)
      break
  }

  return @() {
    watch = [serverConfigs, servProfile]
    fillColor = sf & S_HOVER ? hoverColor : fillColor
    transitions = [{ prop = AnimProp.fillColor, duration = 0.15, easing = Linear }]
    children = rewards.map(function(r) {
      let { rewardsCfg = null } = serverConfigs.value
      let id = r?.rewardId
      let showMark = id in rewardsCfg && isRewardReceived(lootbox, id, rewardsCfg[id], servProfile.value)
      return {
        children = [
          mkRewardPlate(r, REWARD_STYLE_TINY)
          showMark ? mkRewardReceivedMark(REWARD_STYLE_TINY) : null
          !showMark && (r?.isFixed || r?.isJackpot) ? mkRewardFixedIcon(REWARD_STYLE_TINY) : null
        ]
      }
    })
  }.__update(slots > REWARDS ? infoCanvasBig : infoCanvasSmall)
}

function progressBar(stepsFinished, stepsToNext, ovr = {}) {
  if (stepsToNext - stepsFinished <= 0)
    return { size = [flex(), barHeight] }
  let questCompletion = stepsFinished.tofloat() / stepsToNext

  return {
    rendObj = ROBJ_BOX
    size = [flex(), barHeight]
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

function mkLootboxImageWithTimer(name, width, timeRange, reqPlayerLevel, sizeMul = 1.0) {
  let imageSize = [width, lootboxHeight].map(@(v) (v * (customLootboxCfg?[name].sizeMul ?? sizeMul)).tointeger())
  let blockSize = !customLootboxCfg?[name].sizeMul ? [width, lootboxHeight] : [width, min(imageSize[1], hdpx(400))]
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
      mkLoootboxImage(name, null,
        {
          size = imageSize
          picSaturate = isActive.value ? 1.0 : 0.2
          brightness = isActive.value ? 1.0 : 0.5
        },
        customLootboxCfg?[name].img)
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

let mkBtnContent = @(img, text, ovr = {}) {
  key = text
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    !img ? null : {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FILL
      image = Picture($"{img}:{iconSize}:{iconSize}:P")
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
    watch = [bestCampLevel, canShowAds, adBudget]
    children = mkCustomButton(
      cost > adBudget.value
          ? mkBtnContent(null, cost <= 1 ? loc("playOneBattle") : loc("playBattles", { count = cost }))
        : mkBtnContent("ui/gameuiskin#watch_ads.svg", loc("shop/watchAdvert/short"), adsButtonCounter),
      @() bestCampLevel.value >= reqPlayerLevel
          ? onSchRewardReceive(adReward)
        : openMsgBox({ text = loc("lootbox/availableAfterLevel", { level = colorize("@mark", reqPlayerLevel) }) }),
      (bestCampLevel.value >= reqPlayerLevel
        && canShowAds.value
        && adReward?.isReady
        && (cost < adBudget.value)
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
  openEventQuestsWnd,
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
  let { start = 0, end = 0 } = timeRange
  let isActive = Computed(@() bestCampLevel.value >= reqPlayerLevel
    && start < serverTime.value
    && (end <= 0 || end > serverTime.value))
  let adReward = Computed(@() schRewards.value.findvalue(
    @(r) "rewards" not in r ? (r.lootboxes?[name] ?? 0) > 0 //compatibility with 2024.04.14
      : (null != r.rewards.findvalue(@(g) g.id == name && g.gType == G_LOOTBOX))))

  return @() {
    watch = [isActive, balance, adReward]
    key = name
    flow = FLOW_HORIZONTAL
    gap = hdpx(40)
    animations = revealBtnsAnimation
    children = [
      adReward.value != null ? mkAdsBtn(reqPlayerLevel, adReward.value) : null
      textButtonPricePurchase(hasBulkPurchase ? utf8ToUpper(loc("events/oneReward")) : null,
        mkCurrencyComp(price, currencyId),
        @() onPurchase(lootbox, price, currencyId),
        (!isActive.value || (balance.value?[currencyId] ?? 0) < price ? buttonStyles.COMMON : {})
          .__merge({ hotkeys = ["^J:X"] }))
      !hasBulkPurchase ? null
        : textButtonPricePurchase(utf8ToUpper(loc("events/tenRewards")),
            mkCurrencyComp(price * 10, currencyId),
            @() onPurchase(lootbox, price * 10, currencyId, 10),
            (!isActive.value || (balance.value?[currencyId] ?? 0) < price * 10 ? buttonStyles.COMMON : {})
              .__merge({ hotkeys = ["^J:Y"] }))
    ]
  }
}

let smallChestIcon = {
  size = [smallChestIconSize, smallChestIconSize]
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"ui/gameuiskin#events_chest_icon.svg:{smallChestIconSize}:{smallChestIconSize}:P")
}

return {
  lootboxInfo
  progressBar
  mkLootboxImageWithTimer
  lootboxHeight
  mkPurchaseBtns

  leaderbordBtn
  questsBtn

  smallChestIcon
  smallChestIconSize
  barHeight
}
