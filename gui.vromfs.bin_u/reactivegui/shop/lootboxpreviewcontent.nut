from "%globalsDarg/darg_library.nut" import *
let { getLootboxImage, getLootboxFallbackImage, getLootboxName
} = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { getLootboxRewardsViewInfo, fillRewardsCounts, NO_DROP_LIMIT
} = require("%rGui/rewards/rewardViewInfo.nut")
let { REWARD_STYLE_MEDIUM, mkRewardPlate, mkRewardReceivedMark, mkRewardFixedIcon, mkReceivedCounter
} = require("%rGui/rewards/rewardPlateComp.nut")
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


let lootboxImageSize = hdpxi(400)

let spinner = mkSpinner(hdpx(100))

let { boxSize, boxGap } = REWARD_STYLE_MEDIUM
let columnsCount = (saSize[0] + saBorders[0] + boxGap) / (boxSize + boxGap) //allow items a bit go out of safearea to fit more items
let itemsBlockWidth = isWidescreen ? saSize[0] : columnsCount * (boxSize + boxGap)

let mkText = @(text, style) {
  text
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  fontFx = FFT_GLOW
  fontFxFactor = max(64, hdpx(64))
  fontFxColor = 0xFF000000
}.__update(style)

function lootboxImageWithTimer(lootbox) {
  let { name, timeRange = null, reqPlayerLevel = 0 } = lootbox
  let { start = 0, end = 0 } = timeRange

  let adReward = Computed(@() schRewards.value.findvalue(@(r) (r.lootboxes?[name] ?? 0) > 0))
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

function mkReward(reward) {
  let { rType, id, dropLimit, dropLimitRaw, received = 0 } = reward
  local ovr = {}
  if (rType == "unitUpgrade" || rType == "unit")
    ovr = {
      behavior = Behaviors.Button
      onClick = @() unitDetailsWnd({
        name = id,
        isUpgraded = rType == "unitUpgrade"
      })
      sound = { click  = "click" }
      clickableInfo = loc("mainmenu/btnPreview")
    }
  let isAllReceived = dropLimit != NO_DROP_LIMIT && dropLimit <= received
  return {
    children = [
      mkRewardPlate(reward, REWARD_STYLE_MEDIUM, ovr)
      isAllReceived ? mkRewardReceivedMark(REWARD_STYLE_MEDIUM)
        : (reward?.isFixed ?? reward?.isJackpot) ? mkRewardFixedIcon(REWARD_STYLE_MEDIUM)
        : dropLimitRaw != NO_DROP_LIMIT ? mkReceivedCounter(received, dropLimit)
        : null
    ]
  }
}

let itemsBlock = @(rewards, width, ovr = {}) function() {
  let slotsInRow = 2 * max(1, (width + boxGap).tointeger() / (boxSize + boxGap) / 2)
  let rows = []
  local slotsLeft = 0
  foreach(r in rewards.get()) {
    if (r.slots > slotsLeft) {
      rows.append([])
      slotsLeft = slotsInRow
    }
    slotsLeft -= r.slots
    rows.top().append(mkReward(r))
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
          mkText(loc("events/lootboxContains"), fontSmall)
          itemsBlock(allRewards, width)
        ]
      : [
          mkText(loc("jackpot/rewardsHeader"), fontSmall)
          itemsBlock(Computed(@() allRewards.get().slice(0, jackpotCount.get())), width)
          mkText(loc("events/lootboxContains"), fontSmall)
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
          { hplace = ALIGN_CENTER }.__update(fontSmall))
        lootboxImageWithTimer(lootbox)
        itemsBlock(mkLootboxRewardsComp(lootbox), itemsBlockWidth, { halign = ALIGN_CENTER })
      ]
    }.__update(ovr)

let lootboxHeader = @(lootbox) mkText(getLootboxName(lootbox.name, lootbox?.meta.event), fontSmall)

return {
  lootboxPreviewContent
  lootboxImageWithTimer
  lootboxContentBlock
  lootboxHeader
}
