from "%globalsDarg/darg_library.nut" import *
let { bpCardStyle, bpCardPadding, bpCardMargin } = require("%rGui/battlePass/bpCardsStyle.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { bpProgressbarEmpty, bpProgressbarFull, progressIconSize } = require("%rGui/battlePass/battlePassPkg.nut")

let halfWidthProgressIcon = progressIconSize[0] / 2

let bpBorderProgressIcon = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpxi(2)
  commands = [
    [VECTOR_LINE, 0, 0, 98, 0],
    [VECTOR_LINE, 98, 0, 98, 70],
    [VECTOR_LINE, 98, 70, 48, 100],
    [VECTOR_LINE, 48, 100, 0, 70],
    [VECTOR_LINE, 0, 70, 0, 0]
  ]
}

let bpProgressIcon = @(progress, curStage) @() {
  watch = curStage
  children = [
    {
      size = progressIconSize
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#bp_progress_icon.svg:{progressIconSize[0]}:{progressIconSize[1]}:P")
      color = curStage.get() == progress ? 0xFFFFFFFF
        : curStage.get() > progress ? 0xFF36C574
        : 0xFF000000
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_TEXT
        text = progress
        color = curStage.get() >= progress
          ? 0xFF000000
          : 0xFFFFFFFF
      }.__update(fontSmall)
    }
    curStage.get() < progress ? bpBorderProgressIcon : null
  ]
}

let emptyStage = {
  size = progressIconSize
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
}

function bpLineBetweenLevelIconsSimple(stage, curStage, pairedStages = null, idx = null, rewardsStages = null) {
  local curSlots = stage?.viewInfo.slots ?? 1
  if (pairedStages != null && idx != null)
    curSlots = max(curSlots, pairedStages[idx]?.viewInfo?.slots ?? 1)

  local nextSlotsFromStage = stage.nextSlots ?? (rewardsStages != null && idx != null ? rewardsStages[idx+1]?.viewInfo?.slots ?? 1 : 1)
  local nextSlots = nextSlotsFromStage
  if (pairedStages != null && idx != null)
    nextSlots = max(nextSlots, pairedStages[idx+1]?.viewInfo?.slots ?? 1)

  let curSlotWidth = getRewardPlateSize(curSlots, bpCardStyle)[0]
  let nextSlotWidth = getRewardPlateSize(nextSlots, bpCardStyle)[0]
  let widthLine = (curSlotWidth + nextSlotWidth) / 2 + 2 * bpCardPadding[1] - progressIconSize[0] + bpCardMargin
  return @() {
    watch = curStage
    size = [widthLine, hdpx(15)]
    pos = [0, hdpx(16)]
    children = stage?.isVip ? null
      : (stage.progress < curStage.get() ? bpProgressbarFull : bpProgressbarEmpty)
  }
}

function bpProgressBarSimple(rewardsStages, curStage, pairedStages = null) {
  local firstSlots = rewardsStages?[0].viewInfo.slots ?? 1
  if (pairedStages != null && pairedStages.len() > 0)
    firstSlots = max(firstSlots, pairedStages[0]?.viewInfo?.slots ?? 1)
  let halfWidthFirstSlot = getRewardPlateSize(firstSlots, bpCardStyle)[0] / 2
  let posFirstElem = halfWidthFirstSlot + bpCardPadding[1] - halfWidthProgressIcon
  let lastIdx = rewardsStages.len() - 1
  let children = []
  foreach(idx, stage in rewardsStages)
    children.append(
      stage?.isVip ? emptyStage : bpProgressIcon(max(0, stage.progress), curStage)
      lastIdx == idx ? null : bpLineBetweenLevelIconsSimple(stage, curStage, pairedStages, idx, rewardsStages) )
  return {
    pos = [ posFirstElem, 0]
    flow = FLOW_HORIZONTAL
    children
  }
}

return bpProgressBarSimple
