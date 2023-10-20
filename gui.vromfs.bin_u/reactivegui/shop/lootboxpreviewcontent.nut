from "%globalsDarg/darg_library.nut" import *
let { getLootboxImage } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { getLootboxRewardsViewInfo, isRewardReceived  } = require("%rGui/rewards/rewardViewInfo.nut")
let { REWARD_STYLE_MEDIUM, mkRewardPlate, mkRewardReceivedMark, mkRewardFixedIcon } = require("%rGui/rewards/rewardPlateComp.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { previewLootbox } = require("lootboxPreviewState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")


let mkText = @(text, style) {
  text
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  fontFx = FFT_GLOW
  fontFxFactor = max(64, hdpx(64))
  fontFxColor = 0xFF000000
}.__update(style)

let lootboxImageSize = hdpxi(270)

let function lootboxImageWithTimer() {
  if (previewLootbox.value == null)
    return { watch = previewLootbox }

  let { name, timeRange = null } = previewLootbox.value
  let { start = 0, end = 0 } = timeRange
  let timeText = Computed(@() start > serverTime.value
      ? loc("lootbox/availableAfter", { time = secondsToHoursLoc(start - serverTime.value) })
    : end > 0 && end < serverTime.value ? loc("lootbox/noLongerAvailable")
    : null)

  return {
    watch = previewLootbox
    size = [lootboxImageSize, lootboxImageSize]
    rendObj = ROBJ_IMAGE
    image = getLootboxImage(name, lootboxImageSize)
    keepAspect = true
    children = @() {
      watch = timeText
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      text = timeText.value
    }.__update(fontTinyShaded)
  }
}

let itemsBlock = @() {
  watch = [previewLootbox, serverConfigs, servProfile]
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  children = wrap(getLootboxRewardsViewInfo(previewLootbox.value, true)
    .map(function(reward) {
        let { rType, id, rewardId = null } = reward
        let { rewardsCfg = null } = serverConfigs.value
        local ovr = {}
        if (rType == "unitUpgrade" || rType == "unit")
          ovr = {
            behavior = Behaviors.Button
            onClick = @() unitDetailsWnd({
              name = id,
              isUpgraded = rType == "unitUpgrade"
            })
            sound = { click  = "click" }
          }
        let showMark = rewardId in rewardsCfg
          && isRewardReceived(previewLootbox.value, rewardId, rewardsCfg[rewardId], servProfile.value)
        return {
          children = [
            mkRewardPlate(reward, REWARD_STYLE_MEDIUM, ovr)
            showMark ? mkRewardReceivedMark(REWARD_STYLE_MEDIUM) : null
            !showMark && reward?.isFixed ? mkRewardFixedIcon(REWARD_STYLE_MEDIUM) : null
          ]
        }
      }),
    { flow = FLOW_HORIZONTAL, halign = ALIGN_CENTER, width = saSize[0],
      hGap = REWARD_STYLE_MEDIUM.boxGap, vGap = REWARD_STYLE_MEDIUM.boxGap })
}

let lootboxPreviewContent = {
  size = flex()
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    mkText(loc("events/lootboxContains"),
      { hplace = ALIGN_CENTER }.__update(fontSmall))
    lootboxImageWithTimer
    itemsBlock
  ]
}

return lootboxPreviewContent
