from "%globalsDarg/darg_library.nut" import *
let { roundToDigits } = require("%sqstd/math.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { G_LOOTBOX } = require("%appGlobals/rewardType.nut")
let { getLootboxImage, getLootboxFallbackImage, getLootboxName
} = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { getLootboxRewardsViewInfo, fillRewardsCounts, NO_DROP_LIMIT
} = require("%rGui/rewards/rewardViewInfo.nut")
let { REWARD_STYLE_MEDIUM, mkRewardPlate, mkRewardReceivedMark, mkRewardFixedIcon, mkReceivedCounter,
  mkRewardLocked } = require("%rGui/rewards/rewardPlateComp.nut")
let { mkLootboxChancesComp, mkIsLootboxChancesInProgress } = require("%rGui/rewards/lootboxRewardChances.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { lootboxInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { eventSeason, bestCampLevel } = require("%rGui/event/eventState.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { mkGoodsTimeTimeProgress } = require("%rGui/shop/goodsView/sharedParts.nut")
let { schRewards } = require("%rGui/shop/schRewardsState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { getStepsToNextFixed } = require("lootboxPreviewState.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let currencyStyles = require("%rGui/components/currencyStyles.nut")
let { CS_COMMON } = currencyStyles

let lootboxImageSize = hdpxi(400)

let spinner = mkSpinner(hdpx(100))

let { boxSize, boxGap } = REWARD_STYLE_MEDIUM
let columnsCount = (saSize[0] + saBorders[0] + boxGap) / (boxSize + boxGap) //allow items a bit go out of safearea to fit more items
let itemsBlockWidth = isWidescreen ? saSize[0] : columnsCount * (boxSize + boxGap)

let mkText = @(text, ovr = {}) {
  text
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  fontFx = FFT_GLOW
  fontFxFactor = max(64, hdpx(64))
  fontFxColor = 0xFF000000
}.__update(fontSmall, ovr)

function lootboxImageWithTimer(lootbox) {
  let { name, timeRange = null, reqPlayerLevel = 0 } = lootbox
  let { start = 0, end = 0 } = timeRange

  let adReward = Computed(@() schRewards.value.findvalue(
    @(r) "rewards" not in r ? (r.lootboxes?[name] ?? 0) > 0 //compatibility with 2024.04.14
      : (null != r.rewards.findvalue(@(g) g.id == name && g.gType == G_LOOTBOX))))
  let needAdtimeProgress = Computed(@() !lootboxInProgress.value
    && !(adReward.value?.isReady ?? true))

  let timeText = Computed(@() bestCampLevel.value < reqPlayerLevel
      ? loc("lootbox/reqCampaignLevel", { reqLevel = reqPlayerLevel })
    : start > serverTime.value
      ? loc("lootbox/availableAfter", { time = secondsToHoursLoc(start - serverTime.value) })
    : end > 0 && end < serverTime.value ? loc("lootbox/noLongerAvailable")
    : null)

  return @() {
    watch = [timeText, eventSeason]
    size = [lootboxImageSize, lootboxImageSize]
    rendObj = ROBJ_IMAGE
    image = getLootboxImage(name, eventSeason.value, lootboxImageSize)
    fallbackImage = getLootboxFallbackImage(lootboxImageSize)
    keepAspect = true
    brightness = timeText.value == null ? 1.0 : 0.5
    picSaturate = timeText.value == null ? 1.0 : 0.2
    children = [
      @() {
        watch = [needAdtimeProgress, adReward, lootboxInProgress]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = [
          lootboxInProgress.value ? spinner : null
          !needAdtimeProgress.value ? null
            : mkGoodsTimeTimeProgress(adReward.value)
        ]
      }

      @() {
        watch = [timeText, needAdtimeProgress, lootboxInProgress]
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        vplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        text = lootboxInProgress.value || needAdtimeProgress.value ? null : timeText.value
      }.__update(fontTinyShaded)
    ]
  }
}

let mkTooltipText = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(400)
  halign = ALIGN_CENTER
  text
}.__update(fontSmall)

let mkCurrencyComp = @(count, chance, currencyId, style = CS_COMMON) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = style.iconGap
  children = [
    mkText(loc("item/chance"))
    mkCurrencyImage(currencyId, style.iconSize, { key = style?.iconKey })
    mkText($"{count}{colon}{chance}%")
  ]
}

function mkTextForChance(rewardId, chances = null, count = null, currencyId = "") {
  if (chances == null)
    return mkText(loc("item/chance/error"))

  let chance = roundToDigits(chances.percents[rewardId], 2)
  return count ? mkCurrencyComp(decimalFormat(count), chance, currencyId)
    : mkText($"{loc("item/chance")}{colon}{chance}%")
}

function mkJackpotChanceText(id, chances, mainChances, stepsToFixed) {
  if(chances == null || mainChances == null)
    return loc("item/chance/error")

  let chance = roundToDigits(chances.percents[id], 2)
  let mainChance = roundToDigits(mainChances.percents[id], 2)
  let stepsToFixedJackpot = stepsToFixed[1] - stepsToFixed[0]

  return "\n".concat($"{loc("item/chance")}{colon}{mainChance}%",
    $"{loc("item/chance/jackpot", { count = stepsToFixedJackpot })}{colon}{chance}%")
}

function mkJackpotChanceContent(reward, lootbox, mainPercents, mainChanceInProgress) { //-return-different-types
  let { rewardId = null, parentSource = "", isLastReward = false } = reward
  let stepsToFixed = getStepsToNextFixed(lootbox, serverConfigs.get(), servProfile.get())

  if (isLastReward)
    return loc("item/chance/lastRewardJackpot",
      { count = stepsToFixed[1] - stepsToFixed[0] })

  let jackpotChances = mkLootboxChancesComp(parentSource)

  let jackpotInProgress = mkIsLootboxChancesInProgress(parentSource)
  let isInProgress = Computed(@() mainChanceInProgress.get() || jackpotInProgress.get())

  return @() {
    watch = [isInProgress, mainPercents, jackpotChances]
    flow = FLOW_VERTICAL
    sound = { attach = "click" }
    gap = hdpx(5)
    halign = ALIGN_LEFT
    children = isInProgress.get() ? spinner
      : mkTooltipText(mkJackpotChanceText(rewardId,
          mainPercents.get(),
          jackpotChances.get(),
          stepsToFixed))
    }
}

function mkChanceContent(reward, rewardStatus, lootbox) { //-return-different-types
  let { rewardId = null, agregatedRewards = null, source = "", isLastReward = false } = reward
  let { isAvailable, isAllReceived, isJackpot = false } = rewardStatus

  if (!isAvailable.get() || isAllReceived)
    return isAvailable.get() ? loc("battlepass/receivedRew")
      : loc("battlepass/unavailableRew", { unitName = loc(getUnitLocId(reward.id)) })

  if (isLastReward && !isJackpot)
    return loc("item/chance/lastReward")

  let mainChances = mkLootboxChancesComp(source)
  let isInProgress = mkIsLootboxChancesInProgress(source)

  if (isJackpot)
    return mkJackpotChanceContent(reward, lootbox, mainChances, isInProgress)

  return @() {
    watch = [isInProgress, mainChances]
    flow = FLOW_VERTICAL
    sound = { attach = "click" }
    gap = hdpx(5)
    halign = ALIGN_LEFT
    children = isInProgress.get() ? spinner
      : agregatedRewards != null ? agregatedRewards.map(@(r)
        mkTextForChance(r.id, mainChances.get(), r.count, reward.id))
      : mkTextForChance(rewardId, mainChances.get())
  }
}

function mkReward(reward, lootbox) {
  let { rType, id, dropLimit, dropLimitRaw, received = 0 } = reward
  let stateFlags = Watched(0)
  let key = {}
  local ovr = {}
  if (rType == "unitUpgrade" || rType == "unit")
    ovr = {
      onClick = @() unitDetailsWnd({
        name = id,
        isUpgraded = rType == "unitUpgrade"
      })
      sound = { click  = "click" }
      clickableInfo = loc("mainmenu/btnPreview")
    }
  let isAllReceived = dropLimit != NO_DROP_LIMIT && dropLimit <= received
  let isAvailable = Computed(@() rType != "skin" || id in myUnits.get())

  return @() {
    watch = [isAvailable, stateFlags]
    behavior = Behaviors.Button
    onDetach = tooltipDetach(stateFlags)
    onElemState = withTooltip(stateFlags, key, @() { content = mkChanceContent(reward, {
      isAvailable,
      isAllReceived,
      isJackpot = reward?.isJackpot
    }, lootbox)})
    key
    children = [
      mkRewardPlate(reward, REWARD_STYLE_MEDIUM)
      !isAvailable.get() ? mkRewardLocked(REWARD_STYLE_MEDIUM)
        : isAllReceived ? mkRewardReceivedMark(REWARD_STYLE_MEDIUM)
        : (reward?.isFixed ?? reward?.isJackpot) ? mkRewardFixedIcon(REWARD_STYLE_MEDIUM)
        : dropLimitRaw != NO_DROP_LIMIT ? mkReceivedCounter(received, dropLimit)
        : null
    ]
  }.__update(ovr)
}

let itemsBlock = @(rewards, width, ovr = {}, lootbox = null) function() {
  let slotsInRow = 2 * max(1, (width + boxGap).tointeger() / (boxSize + boxGap) / 2)
  let rows = []
  local slotsLeft = 0
  foreach(r in rewards.get()) {
    if (r.slots > slotsLeft) {
      rows.append([])
      slotsLeft = slotsInRow
    }
    slotsLeft -= r.slots
    rows.top().append(mkReward(r, lootbox))
  }
  return {
    watch = rewards
    size = [width, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = boxGap
    children = rows.map(@(children) {
      flow = FLOW_HORIZONTAL
      gap = boxGap
      children
    })
  }.__update(ovr)
}

let mkLootboxRewardsComp = @(lootbox)
  Computed(@() fillRewardsCounts(getLootboxRewardsViewInfo(lootbox, true), servProfile.get(), serverConfigs.get()))

let function lootboxContentBlock(lootbox, width, ovr = {}) {
  let allRewards = mkLootboxRewardsComp(lootbox)
  let jackpotCount = Computed(@() allRewards.get().findindex(@(r) !(r?.isFixed || r?.isJackpot)))
  return @() {
    key = {}
    watch = jackpotCount
    size = [width, SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = REWARD_STYLE_MEDIUM.boxGap
    children = jackpotCount.get() == 0
      ? [
          mkText(loc("events/lootboxContains"))
          itemsBlock(allRewards, width)
        ]
      : [
          mkText(loc("jackpot/rewardsHeader"))
          itemsBlock(Computed(@() allRewards.get().slice(0, jackpotCount.get())), width, {}, lootbox)
          mkText(loc("events/lootboxContains"))
          itemsBlock(Computed(@() allRewards.get().slice(jackpotCount.get())), width)
        ]
    animations = wndSwitchAnim
  }.__update(ovr)
}

let lootboxPreviewContent = @(lootbox, ovr = {}) lootbox == null ? { size = flex() }.__update(ovr)
  : {
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [
        mkText(loc("events/lootboxContains"),
          { hplace = ALIGN_CENTER })
        lootboxImageWithTimer(lootbox)
        itemsBlock(mkLootboxRewardsComp(lootbox), itemsBlockWidth, { halign = ALIGN_CENTER })
      ]
    }.__update(ovr)

let lootboxHeader = @(lootbox) mkText(getLootboxName(lootbox.name, lootbox?.meta.event))

return {
  lootboxPreviewContent
  lootboxImageWithTimer
  lootboxContentBlock
  lootboxHeader
}
