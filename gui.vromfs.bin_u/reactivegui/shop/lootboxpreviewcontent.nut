from "%globalsDarg/darg_library.nut" import *
let { getLootboxImage, getLootboxFallbackImage } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { getLootboxRewardsViewInfo, fillRewardsCounts, NO_DROP_LIMIT
} = require("%rGui/rewards/rewardViewInfo.nut")
let { REWARD_STYLE_MEDIUM, mkRewardPlate, mkRewardReceivedMark, mkRewardFixedIcon, mkReceivedCounter
} = require("%rGui/rewards/rewardPlateComp.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { previewLootbox } = require("lootboxPreviewState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { lootboxInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { eventSeason, bestCampLevel } = require("%rGui/event/eventState.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { mkGoodsTimeTimeProgress } = require("%rGui/shop/goodsView/sharedParts.nut")
let { schRewards } = require("%rGui/shop/schRewardsState.nut")


let lootboxImageSize = hdpxi(270)

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

function lootboxImageWithTimer() {
  if (previewLootbox.value == null)
    return { watch = previewLootbox }

  let { name, timeRange = null, reqPlayerLevel = 0 } = previewLootbox.value
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

  return {
    watch = [previewLootbox, timeText, eventSeason]
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

function itemsBlock() {
  let rewards = fillRewardsCounts(getLootboxRewardsViewInfo(previewLootbox.value, true),
    servProfile.value, serverConfigs.value)
  return {
    watch = [serverConfigs, servProfile]
    size = [itemsBlockWidth, SIZE_TO_CONTENT]
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    children = wrap(rewards
      .map(function(reward) {
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
        }),
      { flow = FLOW_HORIZONTAL, halign = ALIGN_CENTER, width = itemsBlockWidth,
        hGap = boxGap, vGap = boxGap })
  }
}

let lootboxPreviewContent = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    mkText(loc("events/lootboxContains"),
      { hplace = ALIGN_CENTER }.__update(fontSmall))
    lootboxImageWithTimer
    itemsBlock
  ]
}

return lootboxPreviewContent
