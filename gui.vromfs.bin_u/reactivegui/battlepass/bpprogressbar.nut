from "%globalsDarg/darg_library.nut" import *
let { bpCardStyle, bpCardPadding, bpCardMargin } = require("bpCardsStyle.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { curStage } = require("battlePassState.nut")
let { bpCurProgressbar, bpProgressbarEmpty, bpProgressbarFull } = require("battlePassPkg.nut")

let progressIconSize = [evenPx(54), hdpxi(58)]
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

let bpProgressIcon = @(progress) @() {
  watch = curStage
  children = [
    {
      size = progressIconSize
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#bp_progress_icon.svg:{progressIconSize[0]}:{progressIconSize[1]}:P")
      color = curStage.value == progress ? 0xFFFFFFFF
        : curStage.value > progress ? 0xFF36C574
        : 0xFF000000
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_TEXT
        text = progress
        color = curStage.value >= progress
          ? 0xFF000000
          : 0xFFFFFFFF
      }.__update(fontSmall)
    }
    curStage.value < progress ? bpBorderProgressIcon : null
  ]
}

let function bpLineBetweenLevelIcons(stage) {
  let curSlotWidth = getRewardPlateSize(stage?.viewInfo.slots ?? 1, bpCardStyle)[0]
  let nextSlotWidth = getRewardPlateSize(stage.nextSlots, bpCardStyle)[0]
  let widthLine = (curSlotWidth + nextSlotWidth) / 2 + 2 * bpCardPadding[1] - progressIconSize[0] + bpCardMargin
  return @() {
    watch = curStage
    size = [widthLine, hdpx(15)]
    pos = [0, hdpx(16)]
    children = stage.progress == curStage.value ? @() bpCurProgressbar({size = [flex(), hdpx(15)]})
      : stage.progress < curStage.value ? bpProgressbarFull
      : bpProgressbarEmpty
  }
}

let function bpProgressBar(rewardsStages) {
  let halfWidthFirstSlot = getRewardPlateSize(rewardsStages?[0].viewInfo.slots ?? 1, bpCardStyle)[0] / 2
  let posFirstElem = halfWidthFirstSlot + bpCardPadding[1] - halfWidthProgressIcon
  let lastIdx = rewardsStages.len() - 1
  let children = []
  foreach(idx, stage in rewardsStages)
    children.append(
      bpProgressIcon(stage.progress)
      lastIdx == idx ? null : bpLineBetweenLevelIcons(stage))
  return {
    pos = [ posFirstElem, 0]
    flow = FLOW_HORIZONTAL
    children
  }
}

return bpProgressBar