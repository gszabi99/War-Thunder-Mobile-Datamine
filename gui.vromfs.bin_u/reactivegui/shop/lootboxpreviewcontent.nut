from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import *
let { roundToDigits } = require("%sqstd/math.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { getLootboxImage, getLootboxName, lootboxFallbackPicture } = require("%appGlobals/config/lootboxPresentation.nut")
let { getLootboxRewardsViewInfo, fillRewardsCounts, NO_DROP_LIMIT
} = require("%rGui/rewards/rewardViewInfo.nut")
let { mkRewardPlate, mkRewardReceivedMark, mkRewardFixedIcon, mkReceivedCounter,
  mkRewardLocked, mkRewardSearchPlate, mkRewardDisabledBkg
} = require("%rGui/rewards/rewardPlateComp.nut")
let { REWARD_STYLE_TINY_SMALL_GAP, REWARD_STYLE_MEDIUM, progressBarHeight
} = require("%rGui/rewards/rewardStyles.nut")
let { mkLootboxChancesComp, mkIsLootboxChancesInProgress } = require("%rGui/rewards/lootboxRewardChances.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { lootboxInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { eventSeason, bestCampLevel, curEventLootboxes } = require("%rGui/event/eventState.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { mkFreeAdsGoodsTimeProgress } = require("%rGui/shop/goodsView/sharedParts.nut")
let { schRewards } = require("%rGui/shop/schRewardsState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { mkButtonHoldTooltip  } = require("%rGui/tooltip.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { getStepsToNextFixed } = require("lootboxPreviewState.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let currencyStyles = require("%rGui/components/currencyStyles.nut")
let { CS_COMMON } = currencyStyles
let { mkUnitFlag } = require("%rGui/unit/components/unitPlateComp.nut")

let lootboxImageSize = hdpxi(400)
let blueprintSize = hdpxi(30)

let spinner = mkSpinner(hdpx(100))

let { boxSize, boxGap } = REWARD_STYLE_MEDIUM
let columnsCount = (saSize[0] + saBorders[0] + boxGap) / (boxSize + boxGap) //allow items a bit go out of safearea to fit more items
let itemsBlockWidth = isWidescreen ? saSize[0] : columnsCount * (boxSize + boxGap)

let maxRewardsInLootboxBig = 24

let chanceStyle = CS_COMMON

let mkUnitPlateClick = @(r) @() unitDetailsWnd({ name = r.id, isUpgraded = r.rType == G_UNIT_UPGRADE })
let mkPlateClickByType = {
  [G_BLUEPRINT] = mkUnitPlateClick,
  [G_UNIT] = mkUnitPlateClick,
  [G_UNIT_UPGRADE] = mkUnitPlateClick,
}

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

  let adReward = Computed(@() schRewards.get().findvalue(
    @(r) "rewards" not in r ? (r.lootboxes?[name] ?? 0) > 0 //compatibility with 2024.04.14
      : (null != r.rewards.findvalue(@(g) g.id == name && g.gType == G_LOOTBOX))))
  let needAdtimeProgress = Computed(@() !lootboxInProgress.get()
    && !(adReward.get()?.isReady ?? true))

  let timeText = Computed(@() bestCampLevel.get() < reqPlayerLevel
      ? loc("lootbox/reqCampaignLevel", { reqLevel = reqPlayerLevel })
    : start > serverTime.get()
      ? loc("lootbox/availableAfter", { time = secondsToHoursLoc(start - serverTime.get()) })
    : end > 0 && end < serverTime.get() ? loc("lootbox/noLongerAvailable")
    : null)

  let isAvailable = Computed(@() timeText.get() == null)
  return @() {
    watch = [isAvailable, eventSeason]
    size = [lootboxImageSize, lootboxImageSize]
    rendObj = ROBJ_IMAGE
    image = getLootboxImage(name, eventSeason.get(), lootboxImageSize)
    fallbackImage = lootboxFallbackPicture
    keepAspect = true
    brightness = isAvailable.get() ? 1.0 : 0.5
    picSaturate = isAvailable.get() ? 1.0 : 0.2
    children = [
      @() {
        watch = [needAdtimeProgress, adReward, lootboxInProgress]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = [
          lootboxInProgress.get() ? spinner : null
          !needAdtimeProgress.get() ? null
            : mkFreeAdsGoodsTimeProgress(adReward.get())
        ]
      }

      @() {
        watch = [timeText, needAdtimeProgress, lootboxInProgress]
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        vplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        text = lootboxInProgress.get() || needAdtimeProgress.get() ? null : timeText.get()
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

let mkChanceRow = @(count, chance, icon) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = chanceStyle.iconGap
  children = [
    mkText(loc("item/chance"))
    icon
    mkText($"{decimalFormat(count)}{colon}{roundToDigits(chance, 2)}%")
  ]
}

let mkTextForChanceCurrency = @(sr, chances, combinedReward)
  mkChanceRow(sr.count, chances.percents[sr.id], mkCurrencyImage(combinedReward.id, chanceStyle.iconSize))

let chancePartCtors = {
  blueprint = @(sr, chances, _)
    mkChanceRow(sr.count, chances.percents[sr.id],
      {
        size = [blueprintSize, blueprintSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/unitskin#blueprint_default_small.avif:{blueprintSize}:{blueprintSize}:P")
        transform = { rotate = -10 }
      })
}

let mkTextForChancePart = @(singleReward, chances, combinedReward)
  (chancePartCtors?[combinedReward.rType] ?? mkTextForChanceCurrency)(singleReward, chances, combinedReward)

function mkJackpotChanceText(id, chances, mainChances, stepsCount) {
  if(chances == null || mainChances == null)
    return loc("item/chance/error")

  let chance = roundToDigits(chances.percents[id], 2)
  let chanceForGuaranteed = $"{loc("item/chance/jackpot", { count = stepsCount })}{colon}{chance}%"

  if (!mainChances.percents?[id] && chances.percents?[id])
    return chanceForGuaranteed

  let mainChance = roundToDigits(mainChances.percents[id], 2)

  return "\n".concat($"{loc("item/chance")}{colon}{mainChance}%", chanceForGuaranteed)
}

function mkJackpotChanceContent(reward, stepsCount, mainPercents, mainChanceInProgress) { //-return-different-types
  let { rewardId = null, parentSource = "", isLastReward = false } = reward

  if (stepsCount < 0)
    return loc("item/chance/alternativeRewardReceived")

  if (isLastReward)
    return loc("item/chance/lastRewardJackpot", { count = stepsCount })

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
          stepsCount))
    }
}

function mkChanceContent(reward, rewardStatus, stepsCount) { //-return-different-types
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
    return mkJackpotChanceContent(reward, stepsCount, mainChances, isInProgress)

  return @() {
    watch = [isInProgress, mainChances]
    flow = FLOW_VERTICAL
    sound = { attach = "click" }
    gap = hdpx(5)
    halign = ALIGN_LEFT
    children = isInProgress.get() ? spinner
      : mainChances.get() == null ? mkText(loc("item/chance/error"))
      : agregatedRewards != null ? agregatedRewards.map(@(r) mkTextForChancePart(r, mainChances.get(), reward))
      : rewardId != null
        ? mkText("".concat(loc("item/chance"), colon, roundToDigits(mainChances.get().percents[rewardId], 2), "%"))
      : null
  }
}

function mkOvrSearchPlate(reward, ovr = {}) {
  let onClick = mkPlateClickByType?[reward.rType](reward)
  let ovr2 = onClick == null ? {}
    : {
        behavior = Behaviors.Button
        onClick
        sound = { click  = "click" }
        clickableInfo = loc("mainmenu/btnPreview")
        skipDirPadNav = true
      }
  return {
    size = flex()
    children = {
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_LEFT
      padding = hdpx(5)
      children = mkRewardSearchPlate
    }.__update(ovr2, ovr)
  }
}

function mkBlueprintPlate(reward, rStyle) {
  let { isJackpot = false } = reward
  let unit = Computed(@() serverConfigs.value?.allUnits?[reward.id])
  return @() {
    watch = unit
    size = flex()
    children = [
      mkOvrSearchPlate(reward, { pos = [0, -progressBarHeight] })
      !isJackpot ? mkUnitFlag(unit.get(), rStyle) : null
    ]
  }
}

let ovrRewardPlateCtors = {
  [G_BLUEPRINT] = mkBlueprintPlate,
  [G_UNIT_UPGRADE] = @(reward, _) mkOvrSearchPlate(reward),
  [G_UNIT] = @(reward, _) mkOvrSearchPlate(reward)
}

function mkReward(reward, lootbox, rStyle) {
  let { rType, id, dropLimit, dropLimitRaw, received = 0, isJackpot = false } = reward
  let stateFlags = Watched(0)
  let key = {}
  local ovr = {}
  let onClick = mkPlateClickByType?[rType](reward)
  if (onClick != null)
    ovr = {
      sound = { click  = "click" }
      clickableInfo = loc("mainmenu/btnPreview")
    }
  let isAllReceived = dropLimit != NO_DROP_LIMIT && dropLimit <= received
  let isAvailable = Computed(@() rType != "skin" || id in myUnits.get())

  local ovrRewardPlate = null
  local stepsToFixed = []

  if (rType in ovrRewardPlateCtors)
    ovrRewardPlate = ovrRewardPlateCtors[rType](reward, rStyle)
  if (isJackpot)
    stepsToFixed = getStepsToNextFixed(lootbox, serverConfigs.get(), servProfile.get())

  let stepsCount = stepsToFixed.len() ? stepsToFixed[1] - stepsToFixed[0] : 0
  let needDisabledBkg = isJackpot && stepsCount < 0 && !isAllReceived

  return @() {
    watch = [isAvailable, stateFlags]
    behavior = Behaviors.Button
    key
    children = [
      mkRewardPlate(reward, rStyle)
      ovrRewardPlate
      !isAvailable.get() ? mkRewardLocked(rStyle)
        : isAllReceived ? mkRewardReceivedMark(rStyle)
        : (reward?.isFixed ?? isJackpot) ? mkRewardFixedIcon(rStyle)
        : dropLimitRaw != NO_DROP_LIMIT ? mkReceivedCounter(received, dropLimit)
        : null
      needDisabledBkg ? mkRewardDisabledBkg : null
    ]
  }.__update(ovr,
    mkButtonHoldTooltip(onClick, stateFlags, key,
      @() {
        content = mkChanceContent(reward,
          {
            isAvailable,
            isAllReceived,
            isJackpot
          },
          stepsCount)
      },
      0.01))
}

let itemsBlock = @(rewards, width, style, ovr = {}, lootbox = null) function() {
  let slotsInRow = 2 * max(1, (width + style.boxGap).tointeger() / (style.boxSize + style.boxGap) / 2)
  let rows = []
  local slotsLeft = 0
  foreach(r in rewards.get()) {
    if (r.slots > slotsLeft) {
      rows.append([])
      slotsLeft = slotsInRow
    }
    slotsLeft -= r.slots
    rows.top().append(mkReward(r, lootbox, style))
  }
  return {
    watch = rewards
    size = [width, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = style.boxGap
    children = rows.map(@(children) {
      flow = FLOW_HORIZONTAL
      gap = style.boxGap
      children
    })
  }.__update(ovr)
}

let mkLootboxRewardsComp = @(lootbox)
  Computed(@() fillRewardsCounts(getLootboxRewardsViewInfo(lootbox, true), servProfile.get(), serverConfigs.get()))


let function lootboxContentBlock(lootbox, width, ovr = {}) {
  let allRewards = mkLootboxRewardsComp(lootbox)
  local style = REWARD_STYLE_MEDIUM
  if(allRewards.get().len() >= maxRewardsInLootboxBig)
    style = REWARD_STYLE_TINY_SMALL_GAP

  let jackpotCount = Computed(@() allRewards.get().findindex(@(r) !(r?.isFixed || r?.isJackpot)))
  let lootBoxWithSameJackpot = Computed(function() {
    if (lootbox.fixedRewards.len() == 0)
      return null
    let rewards = lootbox.fixedRewards.values()
    return curEventLootboxes.get().findvalue(@(lb) lb.name != lootbox.name && lb.fixedRewards.len() > 0
      && null != lb.fixedRewards.findvalue(@(fr) rewards.contains(fr)))
  })
  return @() {
    key = {}
    watch = [jackpotCount, lootBoxWithSameJackpot]
    size = [width, SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = style.boxGap
    children = jackpotCount.get() == 0
      ? [
          mkText(loc("events/lootboxContains"))
          itemsBlock(allRewards, width, style)
        ]
      : [
          lootBoxWithSameJackpot.get() == null ? null
            : mkText(loc("jackpot/sameJackpotHint", {
                current = getLootboxName(lootbox.name, lootbox?.meta.event)
                same = getLootboxName(lootBoxWithSameJackpot.get().name, lootBoxWithSameJackpot.get()?.meta.event)
              }))
          mkText(loc("jackpot/rewardsHeader"))
          itemsBlock(Computed(@() allRewards.get().slice(0, jackpotCount.get())), width, style, {}, lootbox)
          mkText(loc("events/lootboxContains"))
          itemsBlock(Computed(@() allRewards.get().slice(jackpotCount.get())), width, style)
        ].filter(@(v) v != null)
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
        itemsBlock(mkLootboxRewardsComp(lootbox), itemsBlockWidth, REWARD_STYLE_MEDIUM, { halign = ALIGN_CENTER })
      ]
    }.__update(ovr)

let lootboxHeader = @(lootbox) mkText(getLootboxName(lootbox.name, lootbox?.meta.event))

return {
  lootboxPreviewContent
  lootboxImageWithTimer
  lootboxContentBlock
  lootboxHeader
}
