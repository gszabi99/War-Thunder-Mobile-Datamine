from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import *
let { roundToDigits, ceil } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { currencyToFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { getLootboxImage, getLootboxName, lootboxFallbackPicture } = require("%appGlobals/config/lootboxPresentation.nut")
let { getAllLootboxRewardsViewInfo, getLootboxRewardsViewInfo, fillRewardsCounts, NO_DROP_LIMIT,
  getLootboxOpenRewardViewInfo
} = require("%rGui/rewards/rewardViewInfo.nut")
let { mkRewardPlate, mkRewardReceivedMark, mkRewardFixedIcon, mkReceivedCounter,
  mkRewardLocked, mkRewardSearchPlate, mkRewardDisabledBkg, mkRewardUnitFlag
} = require("%rGui/rewards/rewardPlateComp.nut")
let { REWARD_STYLE_TINY_SMALL_GAP, REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM, progressBarHeight
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
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { mkButtonHoldTooltip  } = require("%rGui/tooltip.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { getStepsToNextFixed, openLootboxPreview } = require("lootboxPreviewState.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let currencyStyles = require("%rGui/components/currencyStyles.nut")
let { CS_COMMON } = currencyStyles
let { mkGradGlowText } = require("%rGui/components/gradTexts.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")


let titleFontGrad = mkFontGradient(0xFFFBF1B9, 0xFFCE733B, 11, 6, 2)

let lootboxImageSize = hdpxi(400)
let blueprintSize = hdpxi(30)

let jpBarHeight = hdpx(10)
let jpBorderWidth = hdpx(1)
let jpBgColor = 0x80000000
let jpBarColor = premiumTextColor
let smallChestIconSize = hdpxi(40)

let spinner = mkSpinner(hdpx(100))

let { boxSize, boxGap } = REWARD_STYLE_MEDIUM
let columnsCount = (saSize[0] + saBorders[0] + boxGap) / (boxSize + boxGap) 
let itemsBlockWidth = isWidescreen ? saSize[0] : columnsCount * (boxSize + boxGap)
let headerTextHeight = calc_str_box("A", fontSmallShaded)[1]
let maxNoScrollHeight = saSize[1] - hdpx(110) 

let chanceStyle = CS_COMMON

let getSlotsInRow = @(width, style) 2 * max(1, (width + style.boxGap).tointeger() / (style.boxSize + style.boxGap) / 2)

let mkUnitPlateClick = @(r) @() unitDetailsWnd({ name = r.id, isUpgraded = r.rType == G_UNIT_UPGRADE })
let mkPlateClickByType = {
  [G_BLUEPRINT] = mkUnitPlateClick,
  [G_UNIT] = mkUnitPlateClick,
  [G_UNIT_UPGRADE] = mkUnitPlateClick,
  [G_LOOTBOX] = @(r) @() openLootboxPreview(r.id),
}

let mkText = @(text, ovr = {}) { rendObj = ROBJ_TEXT, text }.__update(fontSmallShaded, ovr)
let mkTextArea = @(text, maxWidth)
  { rendObj = ROBJ_TEXTAREA, text, behavior = Behaviors.TextArea, maxWidth }.__update(fontTinyShaded)

function lootboxImageWithTimer(lootbox, lootboxAmount = null) {
  let { name, timeRange = null, reqPlayerLevel = 0 } = lootbox
  let { start = 0, end = 0 } = timeRange

  let adReward = Computed(@() schRewards.get().findvalue(
    @(r) (null != r.rewards.findvalue(@(g) g.id == name && g.gType == G_LOOTBOX))))
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
      lootboxAmount == null ? null
        : mkGradGlowText(loc("ui/count", { count = lootboxAmount }), fontWtExtraLarge, titleFontGrad)
            .__update({
              halign = ALIGN_RIGHT
              valign = ALIGN_BOTTOM
              vplace = ALIGN_BOTTOM
              hplace = ALIGN_RIGHT
            })
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

let mkTextForChanceCurrency = @(sr, chances, rId)
  mkChanceRow(sr.count, chances.percents[sr.id], mkCurrencyImage(rId, chanceStyle.iconSize))

let chancePartCtors = {
  blueprint = @(sr, chances, _)
    mkChanceRow(sr.count, chances.percents[sr.id],
      {
        size = [blueprintSize, blueprintSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/unitskin#blueprint_default_small.avif:{blueprintSize}:{blueprintSize}:P")
        transform = { rotate = -10 }
      })
  booster = @(sr, chances, rId)
    mkChanceRow(sr.count, chances.percents[sr.id],
      {
        size = [chanceStyle.iconSize, chanceStyle.iconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{getBoosterIcon(rId)}:{chanceStyle.iconSize}:{chanceStyle.iconSize}:P")
      })
}

let mkTextForChancePart = @(singleReward, chances, rType, rId)
  (chancePartCtors?[rType] ?? mkTextForChanceCurrency)(singleReward, chances, rId)

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

function mkJackpotChanceContent(reward, stepsCount, mainPercents, mainChanceInProgress) { 
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

function mkChanceContent(reward, rewardStatus, stepsCount) { 
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

  let rId = Computed(@() currencyToFullId.get()?[reward.id] ?? reward.id)
  return @() {
    watch = [isInProgress, mainChances, rId]
    flow = FLOW_VERTICAL
    sound = { attach = "click" }
    gap = hdpx(5)
    halign = ALIGN_LEFT
    children = isInProgress.get() ? spinner
      : mainChances.get() == null ? mkText(loc("item/chance/error"))
      : agregatedRewards != null ? agregatedRewards.map(@(r) mkTextForChancePart(r, mainChances.get(), reward.rType, rId.get()))
      : rewardId != null
        ? mkText("".concat(loc("item/chance"), colon, roundToDigits(mainChances.get().percents[rewardId], 2), "%"))
      : null
  }
}

function mkPreviewIconImpl(reward, rStyle, ovr = {}) {
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
      children = mkRewardSearchPlate(rStyle)
    }.__update(ovr2, ovr)
  }
}

function mkRewardFlag(reward, rStyle) {
  let unit = Computed(@() serverConfigs.value?.allUnits?[reward.id])
  return @() {
    watch = unit
    children = mkRewardUnitFlag(unit.get(), rStyle)
  }
}

let topLeftIconCtor = {
  [G_BLUEPRINT] = mkRewardFlag,
  [G_UNIT_UPGRADE] = mkRewardFlag,
  [G_UNIT] = mkRewardFlag,
}

let previewIconOvr = {
  [G_BLUEPRINT] = @(_) { pos = [0, -progressBarHeight] },
  [G_LOOTBOX] = @(rStyle) { pos = [0, -rStyle.labelHeight] },
}

let mkPreviewIcon = @(reward, rStyle) mkPreviewIconImpl(reward, rStyle, previewIconOvr?[reward.rType](rStyle) ?? {})

function mkReward(reward, lootbox, rStyle) {
  let { rType, id, dropLimit = NO_DROP_LIMIT, dropLimitRaw = NO_DROP_LIMIT, received = 0,
    isJackpot = false, isOpenReward = false
  } = reward
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
  let isAvailable = Computed(@() rType != "skin" || id in campMyUnits.get())

  local ovrRewardPlate = null
  local stepsToFixed = []

  if (isJackpot)
    stepsToFixed = getStepsToNextFixed(lootbox, serverConfigs.get(), servProfile.get())

  let stepsCount = stepsToFixed.len() ? stepsToFixed[1] - stepsToFixed[0] : 0
  let needDisabledBkg = isJackpot && stepsCount < 0 && !isAllReceived

  let topLeftIcon = !isAvailable.get() ? mkRewardLocked(rStyle)
    : !isAllReceived && (reward?.isFixed ?? isJackpot) ? mkRewardFixedIcon(rStyle)
    : !isAllReceived && dropLimitRaw != NO_DROP_LIMIT ? mkReceivedCounter(received, dropLimit)
    : topLeftIconCtor?[rType](reward, rStyle)

  return @() {
    watch = [isAvailable, stateFlags]
    behavior = Behaviors.Button
    key
    children = [
      mkRewardPlate(reward, rStyle)
      ovrRewardPlate
      onClick == null ? null : mkPreviewIcon(reward, rStyle)
      topLeftIcon
      isAllReceived ? mkRewardReceivedMark(rStyle) : null
      needDisabledBkg ? mkRewardDisabledBkg : null
    ]
  }.__update(ovr,
    mkButtonHoldTooltip(onClick, stateFlags, key,
      @() {
        content = isOpenReward ? loc("lootbox/eachOpenReward")
          : mkChanceContent(reward,
              {
                isAvailable,
                isAllReceived,
                isJackpot
              },
              stepsCount)
      },
      0.01))
}

function itemsBlock(rewards, width, style, ovr = {}, lootbox = null) {
  let slotsInRow = getSlotsInRow(width, style)
  let rows = []
  local slotsLeft = 0
  foreach(r in rewards) {
    if (r.slots > slotsLeft) {
      rows.append([])
      slotsLeft = slotsInRow
    }
    slotsLeft -= r.slots
    rows.top().append(mkReward(r, lootbox, style))
  }
  return {
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

let blockWithHeaderArray = @(text, rewards, width, style, lootbox = null) rewards.len() == 0 ? []
 : [
     mkText(text)
     itemsBlock(rewards, width, style, {}, lootbox)
   ]

function calcBlockHeightWithGap(rewards, slotsInRow, style) {
  if (rewards.len() == 0)
    return 0
  let rows = ceil(rewards.reduce(@(res, r) res + r.slots, 0).tofloat() / slotsInRow).tointeger()
  return headerTextHeight + style.boxGap + rows * (style.boxSize + style.boxGap)
}

let mkStyleComp = @(width, r1, r2, r3) Computed(function() {
  foreach(style in [REWARD_STYLE_MEDIUM, REWARD_STYLE_SMALL]) {
    let slotsInRow = getSlotsInRow(width, style)
    let height = calcBlockHeightWithGap(r1.get(), slotsInRow, style)
      + calcBlockHeightWithGap(r2.get(), slotsInRow, style)
      + calcBlockHeightWithGap(r3.get(), slotsInRow, style)
    if (height <= maxNoScrollHeight)
      return style
  }
  return REWARD_STYLE_TINY_SMALL_GAP
})

let function lootboxContentBlock(lootbox, width, ovr = {}) {
  let allRewards = Computed(@() fillRewardsCounts(getAllLootboxRewardsViewInfo(lootbox), servProfile.get(), serverConfigs.get()))
  let jackpotCount = Computed(@() allRewards.get().findindex(@(r) !(r?.isFixed || r?.isJackpot)))
  let jackpotRewards = Computed(@() allRewards.get().slice(0, jackpotCount.get()))
  let commonRewards = Computed(@() jackpotCount.get() == 0 ? allRewards.get() : allRewards.get().slice(jackpotCount.get()))
  let lootBoxWithSameJackpot = Computed(function() {
    if (lootbox.fixedRewards.len() == 0)
      return null
    let rewards = lootbox.fixedRewards.values()
    return curEventLootboxes.get().findvalue(@(lb) lb.name != lootbox.name && lb.fixedRewards.len() > 0
      && null != lb.fixedRewards.findvalue(@(fr) rewards.contains(fr)))
  })
  let openRewards = Computed(@() getLootboxOpenRewardViewInfo(lootbox, serverConfigs.get())
    .map(@(v) v.$rawset("isOpenReward", true)))

  let style = mkStyleComp(width, openRewards, jackpotRewards, commonRewards)
  return @() {
    key = {}
    watch = [style, jackpotRewards, commonRewards, lootBoxWithSameJackpot, openRewards]
    size = [width, SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = style.get().boxGap
    children = blockWithHeaderArray(loc("lootbox/eachOpenReward"), openRewards.get(), width, style.get())
      .append(lootBoxWithSameJackpot.get() == null ? null
        : mkTextArea(loc("jackpot/sameJackpotHint", {
            current = getLootboxName(lootbox.name)
            same = getLootboxName(lootBoxWithSameJackpot.get().name)
          }), width))
      .extend(
        blockWithHeaderArray(loc("jackpot/rewardsHeader"), jackpotRewards.get(), width, style.get(), lootbox)
        blockWithHeaderArray(loc("events/lootboxContains"), commonRewards.get(), width, style.get())
      )
      .filter(@(v) v != null)
    animations = wndSwitchAnim
  }.__update(ovr)
}

function lootboxPreviewContent(lootbox, ovr = {}) {
  if (lootbox == null)
    return { size = flex() }.__update(ovr)
  let rewards = Computed(@() fillRewardsCounts(getLootboxRewardsViewInfo(lootbox, true), servProfile.get(), serverConfigs.get()))
  return @() {
    watch = rewards
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      mkText(loc("events/lootboxContains"),
        { hplace = ALIGN_CENTER })
      lootboxImageWithTimer(lootbox)
      itemsBlock(
        rewards.get(),
        itemsBlockWidth, REWARD_STYLE_MEDIUM, { halign = ALIGN_CENTER })
    ]
  }.__update(ovr)
}

let lootboxHeader = @(lootbox) mkText(getLootboxName(lootbox.name))

let mkRow = @(children) {
  flow = FLOW_HORIZONTAL
  gap = hdpx(8)
  valign = ALIGN_CENTER
  children
}

let smallChestIcon = {
  size = [smallChestIconSize, smallChestIconSize]
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"ui/gameuiskin#events_chest_icon.svg:{smallChestIconSize}:{smallChestIconSize}:P")
}

function mkJackpotProgressBar(stepsFinished, stepsToNext, ovr = {}) {
  if (stepsToNext - stepsFinished <= 0)
    return { size = [flex(), jpBarHeight] }
  let questCompletion = stepsFinished.tofloat() / stepsToNext

  return {
    rendObj = ROBJ_BOX
    size = [flex(), jpBarHeight]
    fillColor = jpBgColor
    borderWidth = jpBorderWidth
    borderColor = jpBarColor
    children = [
      {
        rendObj = ROBJ_BOX
        size = [pw(100 * questCompletion), jpBarHeight]
        fillColor = jpBarColor
      }
    ]
  }.__update(ovr)
}

let mkJackpotProgress = @(stepsToFixed) @() {
  key = "jackpot_progress" 
  watch = stepsToFixed
  flow = FLOW_VERTICAL
  children = stepsToFixed.value[1] - stepsToFixed.value[0] <= 0 ? null : [
    mkRow([
      {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc("events/jackpot"))
      }.__update(fontVeryTinyAccented)
      {
        rendObj = ROBJ_TEXT
        text = stepsToFixed.value[1] - stepsToFixed.value[0]
      }.__update(fontVeryTinyAccented)
    ])
    mkJackpotProgressBar(stepsToFixed.value[0], stepsToFixed.value[1], { margin = [hdpx(10), 0] })
    mkRow([
      {
        maxWidth = hdpx(400)
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("events/guaranteedReward")
      }.__update(fontVeryTiny)
      { size = [hdpx(10), 0] }
      smallChestIcon
    ])
  ]
}

return {
  lootboxPreviewContent
  lootboxImageWithTimer
  lootboxContentBlock
  lootboxHeader
  mkJackpotProgress
  mkJackpotProgressBar
  smallChestIcon
}
