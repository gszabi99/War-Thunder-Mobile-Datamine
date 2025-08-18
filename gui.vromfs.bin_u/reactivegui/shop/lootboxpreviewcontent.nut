from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import *
let { roundToDigits, ceil, round_by_value } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { currencyToFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { getLootboxImage, getLootboxName, lootboxFallbackPicture } = require("%appGlobals/config/lootboxPresentation.nut")
let { getAllLootboxRewardsViewInfo, getLootboxRewardsViewInfo, fillRewardsCounts, NO_DROP_LIMIT,
  getLootboxOpenRewardViewInfo, isSingleViewInfoRewardEmpty
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
let { mkFreeAdsGoodsTimeProgress, disabledAdsGoodsPlate } = require("%rGui/shop/goodsView/sharedParts.nut")
let { schRewards } = require("%rGui/shop/schRewardsState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { mkButtonHoldTooltip  } = require("%rGui/tooltip.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { getStepsToNextFixed, openLootboxPreview } = require("%rGui/shop/lootboxPreviewState.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let currencyStyles = require("%rGui/components/currencyStyles.nut")
let { CS_COMMON } = currencyStyles
let { mkGradGlowText } = require("%rGui/components/gradTexts.nut")
let { mkCustomButton, mergeStyles } = require("%rGui/components/textButton.nut")
let { PRIMARY } = require("%rGui/components/buttonStyles.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { isProviderInited } = require("%rGui/ads/adsState.nut")


let titleFontGrad = mkFontGradient(0xFFFBF1B9, 0xFFCE733B, 11, 6, 2)

let lootboxImageSize = hdpxi(400)
let blueprintSize = hdpxi(30)

let jpBarHeight = hdpx(10)
let jpBorderWidth = hdpx(1)
let jpBgColor = 0x80000000
let jpBarColor = premiumTextColor
let smallChestIconSize = hdpxi(40)
let nestedBgColor = 0x70000000

let spinner = mkSpinner(hdpx(100))

let { boxSize, boxGap } = REWARD_STYLE_MEDIUM
let columnsCount = (saSize[0] + saBorders[0] + boxGap) / (boxSize + boxGap) 
let itemsBlockWidth = isWidescreen ? saSize[0] : columnsCount * (boxSize + boxGap)
let headerTextHeight = calc_str_box("A", fontSmallShaded)[1]
let maxNoScrollHeight = saSize[1] - hdpx(110) 

let chanceStyle = CS_COMMON

let roundChance = @(chance) chance > 1 ? round_by_value(chance, 0.1) : roundToDigits(chance, 2)

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
        watch = [needAdtimeProgress, adReward, lootboxInProgress, isProviderInited]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = [
          lootboxInProgress.get() ? spinner : null
          needAdtimeProgress.get()
              ? mkFreeAdsGoodsTimeProgress(adReward.get())
            : !isProviderInited.get()
              ? disabledAdsGoodsPlate
            : null
        ]
      }

      @() {
        watch = [timeText, needAdtimeProgress, lootboxInProgress]
        size = FLEX_H
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
    mkText($"{decimalFormat(count)}{colon}{roundChance(chance)}%")
  ]
}

let mkTextForChanceCurrency = @(sr, chances, rId)
  mkChanceRow(sr.count, chances.percents?[sr.id] ?? 0, mkCurrencyImage(rId, chanceStyle.iconSize))

let chancePartCtors = {
  blueprint = @(sr, chances, _)
    mkChanceRow(sr.count, chances.percents?[sr.id] ?? 0,
      {
        size = [blueprintSize, blueprintSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/unitskin#blueprint_default_small.avif:{blueprintSize}:{blueprintSize}:P")
        transform = { rotate = -10 }
      })
  booster = @(sr, chances, rId)
    mkChanceRow(sr.count, chances.percents?[sr.id] ?? 0,
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

  let chance = roundChance(chances.percents?[id] ?? 0)
  let chanceForGuaranteed = $"{loc("item/chance/fixedReward", { count = stepsCount })}{colon}{chance}%"

  if (!mainChances.percents?[id] && chances.percents?[id])
    return chanceForGuaranteed

  let mainChance = roundChance(mainChances.percents?[id] ?? 0)

  return "\n".concat($"{loc("item/chance")}{colon}{mainChance}%", chanceForGuaranteed)
}

function mkJackpotChanceContent(reward, stepsCount, mainPercents, mainChanceInProgress) { 
  let { rewardId = null, parentSource = "", isLastReward = false } = reward

  if (stepsCount < 0)
    return loc("item/chance/alternativeRewardReceived")

  if (isLastReward)
    return loc("item/chance/lastRewardFixed", { count = stepsCount })

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

function mkChanceContent(reward, rewardStatus, stepsCount, dropFromNested) { 
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
  if (dropFromNested == null) {
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
          ? mkText("".concat(loc("item/chance"), colon, roundChance(mainChances.get().percents?[rewardId] ?? 0), "%"))
        : null
    }
  }

  let nestedChances = mkLootboxChancesComp(dropFromNested.source)
  let isInProgressNested = mkIsLootboxChancesInProgress(dropFromNested.source)
  let isInProgressFull = Computed(@() isInProgress.get() || isInProgressNested.get())
  return @() {
    watch = [isInProgressFull, mainChances, nestedChances, rId]
    flow = FLOW_VERTICAL
    sound = { attach = "click" }
    gap = hdpx(5)
    halign = ALIGN_LEFT
    children = isInProgressFull.get() ? spinner
      : mainChances.get() == null || nestedChances.get() == null ? mkText(loc("item/chance/error"))
      : dropFromNested.rewardId not in nestedChances.get().percents ? mkText(loc("jackpot/alreadyReceived"))
      : [ mkText(loc("item/chance/fromNested", { lootboxName = getLootboxName(dropFromNested.rewardId) })) ]
          .extend(
            agregatedRewards != null
                ? agregatedRewards.map(@(r) mkTextForChancePart(r, mainChances.get(), reward.rType, rId.get()))
              : rewardId != null
                ? [mkText("".concat(loc("item/chance"), colon, roundChance(mainChances.get().percents?[rewardId] ?? 0), "%"))]
              : [])
          .append(
            {  size = hdpx(20) },
            mkText(loc("item/chance/withName",
              {
                name = getLootboxName(dropFromNested.id)
                chance = roundChance(nestedChances.get().percents?[dropFromNested.rewardId] ?? 0)
              })))
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
  let unit = Computed(@() serverConfigs.get()?.allUnits?[reward.id])
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

function mkReward(reward, rStyle, lootboxW = null, dropFromNested = null) {
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

  let stepsCount = !isJackpot || lootboxW == null ? Watched(0)
    : Computed(function() {
        let stepsToFixed = getStepsToNextFixed(lootboxW.get(), serverConfigs.get(), servProfile.get())
        return stepsToFixed[1] - stepsToFixed[0]
      })

  return @() {
    watch = [isAvailable, stateFlags, stepsCount]
    behavior = Behaviors.Button
    key
    children = [
      mkRewardPlate(reward, rStyle)
      onClick == null ? null : mkPreviewIcon(reward, rStyle)
      !isAvailable.get() ? mkRewardLocked(rStyle)
        : !isAllReceived && (reward?.isFixed ?? isJackpot) ? mkRewardFixedIcon(rStyle)
        : !isAllReceived && dropLimitRaw != NO_DROP_LIMIT ? mkReceivedCounter(received, dropLimit)
        : topLeftIconCtor?[rType](reward, rStyle)
      isAllReceived ? mkRewardReceivedMark(rStyle) : null
      isJackpot && stepsCount.get() < 0 && !isAllReceived ? mkRewardDisabledBkg : null
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
              stepsCount.get(),
              dropFromNested)
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
    rows.top().append(mkReward(r, style, lootbox))
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

function getLootboxRewardsAutoLast(lootbox, profile, srvConfigs, isAllReceived = false) {
  let res = fillRewardsCounts(getLootboxRewardsViewInfo(lootbox, true), profile, srvConfigs)
  let lastRewardIdx = res.findindex(@(r) r?.isLastReward ?? false)
  if (lastRewardIdx == null)
    return res
  if (isAllReceived || null != res.findindex(@(r) !r?.isLastReward && !isSingleViewInfoRewardEmpty(r, profile)))
    res.remove(lastRewardIdx)
  return res
}

function buttonDots(style) {
  let size = (0.07 * style.boxSize).tointeger() * 2
  return {
    flow = FLOW_HORIZONTAL
    gap = size / 2
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = array(3, {
      size = size
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#circle.svg:{size}:{size}:P")
    })
  }
}

let mkMoreInfoButton = @(reward, style) reward.rType not in mkPlateClickByType ? null
  : mkCustomButton(buttonDots(style), mkPlateClickByType[reward.rType](reward),
      mergeStyles(PRIMARY, { ovr = { size = [style.boxSize, style.boxSize], minWidth = style.boxSize } }))

function mkRewardLootboxInfo(reward, width, style) {
  let { id, dropLimit = NO_DROP_LIMIT, received = 0 } = reward
  let isAllReceived = dropLimit != NO_DROP_LIMIT && dropLimit <= received
  let slotsInRow = getSlotsInRow(width, style) - 1 - reward.slots
  let arrowSize = [style.boxSize * 2 / 3, (style.boxSize / 4) * 2]
  let lootbox = Computed(@() serverConfigs.get()?.lootboxesCfg[id])
  let rewards = Computed(@() lootbox.get() == null ? []
    : getLootboxRewardsAutoLast(lootbox.get(), servProfile.get(), serverConfigs.get(), isAllReceived))
  let visibleCount = Computed(function() {
    local res = 0
    local slotsLeft = slotsInRow
    foreach (idx, r in rewards.get()) {
      let { slots } = r
      if (slots > slotsLeft)
        return res
      else if (slots == slotsLeft)
        return idx == rewards.get().len() - 1 ? res + 1 : res
      res++
      slotsLeft -= slots
    }
    return res
  })
  return @() {
    watch = [rewards, visibleCount]
    size = [width, SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = style.boxGap
    valign = ALIGN_CENTER
    children = [
      mkReward(reward, style)
      {
        size = [style.boxSize - style.boxGap, style.boxSize]
        valign = ALIGN_CENTER
        halign = ALIGN_RIGHT
        children = {
          size = arrowSize
          pos = [style.boxGap, 0]
          rendObj = ROBJ_VECTOR_CANVAS
          fillColor = nestedBgColor
          color = 0
          commands = [[VECTOR_POLY, 0, 50, 100, 0, 100, 100]]
        }
      }
      {
        padding = style.boxGap
        rendObj = ROBJ_SOLID
        color = nestedBgColor
        flow = FLOW_HORIZONTAL
        gap = style.boxGap
        children = rewards.get()
          .slice(0, visibleCount.get())
          .map(@(r) mkReward(r, style, null, reward)) 
          .append(rewards.get().len() == visibleCount.get() ? null : mkMoreInfoButton(reward, style))
      }
    ]
  }
}

let blockWithHeaderArray = @(text, rewards, width, style, lootbox = null) rewards.len() == 0 ? []
 : [
     mkText(text)
     itemsBlock(rewards, width, style, {}, lootbox)
   ]

let blockWithLootboxesInfoArray = @(text, rewards, width, style) rewards.len() == 0 ? []
 : [
     mkText(text)
   ]
     .extend(rewards.map(@(r) mkRewardLootboxInfo(r, width, style)))

function calcBlockHeightWithGap(rewards, slotsInRow, style) {
  if (rewards.len() == 0)
    return 0
  let rows = ceil(rewards.reduce(@(res, r) res + r.slots, 0).tofloat() / slotsInRow).tointeger()
  return headerTextHeight + style.boxGap + rows * (style.boxSize + style.boxGap)
}

let mkStyleComp = @(width, r1, r2, r3, lootboxes) Computed(function() {
  foreach(style in [REWARD_STYLE_MEDIUM, REWARD_STYLE_SMALL]) {
    let slotsInRow = getSlotsInRow(width, style)
    let height = calcBlockHeightWithGap(r1.get(), slotsInRow, style)
      + calcBlockHeightWithGap(r2.get(), slotsInRow, style)
      + calcBlockHeightWithGap(r3.get(), slotsInRow, style)
      + (lootboxes.get().len() == 0 ? 0
        : (headerTextHeight + style.boxGap + lootboxes.get().len() * (style.boxSize + style.boxGap)))
    if (height <= maxNoScrollHeight)
      return style
  }
  return REWARD_STYLE_TINY_SMALL_GAP
})

let function lootboxContentBlock(lootbox, width, ovr = {}) {
  let allRewards = Computed(@(prev) prevIfEqual(prev,
    lootbox.get() == null ? []
      : fillRewardsCounts(getAllLootboxRewardsViewInfo(lootbox.get()), servProfile.get(), serverConfigs.get())))
  let jackpotCount = Computed(@() allRewards.get().findindex(@(r) !(r?.isFixed || r?.isJackpot)) ?? 0)
  let jackpotRewards = Computed(function(prev) {
    let { total = {} } = servProfile.get()?.lootboxStats[lootbox.get()?.name]
    return prevIfEqual(prev,
      allRewards.get().slice(0, jackpotCount.get())
        .filter(@(r) null == r.lockedBy.findvalue(@(l) (total?[l] ?? 0) > 0)))
  })
  let commonRewardsInfo = Computed(function() {
    let full = jackpotCount.get() == 0 ? allRewards.get() : allRewards.get().slice(jackpotCount.get())
    let list = []
    let lootboxes = []
    foreach (r in full)
      if (r.rType == G_LOOTBOX)
        lootboxes.append(r)
      else
        list.append(r)
    return { list, lootboxes }
  })
  let commonRewards = Computed(@() commonRewardsInfo.get().list)
  let rewardLootboxes = Computed(@() commonRewardsInfo.get().lootboxes)

  let lootboxName = Computed(@() lootbox.get()?.name ?? "")
  let lootBoxWithSameJackpot = Computed(function() {
    let { name = "", fixedRewards = {} } = lootbox.get()
    if (fixedRewards.len() == 0)
      return null
    let rewards = fixedRewards.reduce(@(res, fr) res.$rawset(fr?.rewardId ?? fr, true), {}) 
    return curEventLootboxes.get()
      .findvalue(@(lb) lb.name != name
        && null != lb.fixedRewards.findvalue(@(fr) (fr?.rewardId ?? fr) in rewards)) 
      ?.name
  })
  let openRewards = Computed(@() lootbox.get() == null ? []
    : getLootboxOpenRewardViewInfo(lootbox.get(), serverConfigs.get())
      .map(@(v) v.$rawset("isOpenReward", true)))
  let lockedJackpotCount = Computed(@() jackpotRewards.get().findvalue(@(r) r.lockedBy.len() > 0) == null ? 0
    : getStepsToNextFixed(lootbox.get(), serverConfigs.get(), servProfile.get())[1])

  let style = mkStyleComp(width, openRewards, jackpotRewards, commonRewards, rewardLootboxes)
  return @() {
    key = {}
    watch = [style, jackpotRewards, commonRewards, lootBoxWithSameJackpot, openRewards, rewardLootboxes, lootboxName]
    size = [width, SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = style.get().boxGap
    children = blockWithHeaderArray(loc("lootbox/eachOpenReward"), openRewards.get(), width, style.get())
      .append(lootBoxWithSameJackpot.get() == null || jackpotRewards.get().len() == 0 ? null
        : mkTextArea(loc("fixedReward/sameRewardHint", {
            current = getLootboxName(lootboxName.get())
            same = getLootboxName(lootBoxWithSameJackpot.get())
          }), width),
          lockedJackpotCount.get() > 0
            ? mkTextArea(loc("jackpot/locked/info", { count = lockedJackpotCount.get() }), width )
            : null)
      .extend(
        blockWithLootboxesInfoArray(loc("events/lootboxContains/special"), rewardLootboxes.get(), width, style.get())
        blockWithHeaderArray(loc("fixedReward/rewardsHeader"), jackpotRewards.get(), width, style.get(), lootbox)
        blockWithHeaderArray(rewardLootboxes.get().len() == 0 ? loc("events/lootboxContains") : loc("events/lootboxContains/other"),
          commonRewards.get(), width, style.get())
      )
      .filter(@(v) v != null)
    animations = wndSwitchAnim
  }.__update(ovr)
}

function lootboxPreviewContent(lootbox, ovr = {}) {
  if (lootbox == null)
    return { size = flex() }.__update(ovr)
  let rewards = Computed(@() getLootboxRewardsAutoLast(lootbox, servProfile.get(), serverConfigs.get()))
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
        text = utf8ToUpper(loc("events/fixedReward"))
      }.__update(fontVeryTinyAccented)
      {
        rendObj = ROBJ_TEXT
        text = stepsToFixed.value[1] - stepsToFixed.value[0]
      }.__update(fontVeryTinyAccented)
    ])
    mkJackpotProgressBar(stepsToFixed.value[0], stepsToFixed.value[1], { margin = const [hdpx(10), 0] })
    mkRow([
      {
        maxWidth = hdpx(400)
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("events/guaranteedReward")
      }.__update(fontVeryTiny)
      { size = const [hdpx(10), 0] }
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
