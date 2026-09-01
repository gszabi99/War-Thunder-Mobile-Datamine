from "%globalsDarg/darg_library.nut" import *
from "%rGui/battlePass/bpCardsStyle.nut" import bpCardStyle, bpCardPadding, bpCardMargin
from "%rGui/battlePass/passPkg.nut" import bpCurProgressbar, bpProgressbarEmpty, bpProgressbarFull, progressIconSize,
  mkBuyLevelBlock
from "%rGui/battlePass/passRewardsListComp.nut" import purchBtnHeight
from "%rGui/rewards/rewardStyles.nut" import getRewardPlateSize


let buyLevelBlockOffs = -(purchBtnHeight + hdpx(10))

let halfWidthProgressIcon = progressIconSize[0] / 2

let bpBorderProgressIcon = {
  size = FLEX
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

let bpProgressIcon = @(progress, loopMultiply, curStage) @() {
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
        text = loopMultiply > 0 ? loc("icon/infinity") : progress
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

function mkStageIcon(stage, curStage, levelPrice, isLevelPurchaseInProgress, buyLevelMsg) {
  let icon = bpProgressIcon(max(0, stage.progress), stage?.loopMultiply ?? 0, curStage)
  if (!(stage?.canBuyLevel ?? false))
    return icon
  return {
    size = progressIconSize
    children = [
      icon
      {
        hplace = ALIGN_CENTER
        vplace = ALIGN_TOP
        pos = [0, buyLevelBlockOffs]
        children = mkBuyLevelBlock(true, stage.viewInfo, levelPrice, isLevelPurchaseInProgress, buyLevelMsg, stage)
      }
    ]
  }
}

function bpLevelBuyOverflow(rewardsStages, buyIdx, levelPrice, isLevelPurchaseInProgress, buyLevelMsg) {
  let stage = rewardsStages[buyIdx]
  let buyBlockWidth = calc_comp_size(
    mkBuyLevelBlock(true, stage.viewInfo, levelPrice, isLevelPurchaseInProgress, buyLevelMsg, stage))[0]
  let cardSize = getRewardPlateSize(1, bpCardStyle)[0] + 2 * bpCardPadding[1] + bpCardMargin
  let cardsToEnd = rewardsStages.len() - buyIdx
  let overflowPastCardsRow = buyBlockWidth / 2 - (cardsToEnd - 0.5) * cardSize
  if (overflowPastCardsRow <= 0)
    return 0
  let firstCardWidth = getRewardPlateSize(rewardsStages[0].viewInfo?.slots ?? 1, bpCardStyle)[0] + 2 * bpCardPadding[1]
  let lastCardWidth = getRewardPlateSize(
    rewardsStages[rewardsStages.len() - 1].viewInfo?.slots ?? 1, bpCardStyle)[0] + 2 * bpCardPadding[1]
  let iconsVsCardsRowGap = (firstCardWidth + lastCardWidth) / 2 - progressIconSize[0]
  return overflowPastCardsRow + iconsVsCardsRowGap
}

function bpLineBetweenLevelIcons(stage, curStage, pointsCurStage, pointsPerStage) {
  let curSlotWidth = getRewardPlateSize(stage?.viewInfo.slots ?? 1, bpCardStyle)[0]
  let nextSlotWidth = getRewardPlateSize(stage.nextSlots, bpCardStyle)[0]
  let widthLine = (curSlotWidth + nextSlotWidth) / 2 + 2 * bpCardPadding[1] - progressIconSize[0] + bpCardMargin
  return @() {
    watch = curStage
    size = [widthLine, hdpx(15)]
    pos = const [0, hdpx(16)]
    children = stage?.isVip ? null
      : stage.progress == curStage.get() ? bpCurProgressbar(pointsCurStage, pointsPerStage, {size = const [FLEX, hdpx(15)]})
      : stage.progress < curStage.get() ? bpProgressbarFull
      : bpProgressbarEmpty
  }
}

function bpProgressBar(rewardsStages, curStage, pointsCurStage, pointsPerStage,
  levelPrice, isLevelPurchaseInProgress, buyLevelMsg
) {
  let halfWidthFirstSlot = getRewardPlateSize(rewardsStages?[0].viewInfo.slots ?? 1, bpCardStyle)[0] / 2
  let posFirstElem = halfWidthFirstSlot + bpCardPadding[1] - halfWidthProgressIcon
  let lastIdx = rewardsStages.len() - 1
  let buyIdx = rewardsStages.findindex(@(s) !(s?.isVip ?? false) && (s?.canBuyLevel ?? false))
  let buyOverflow = buyIdx == null ? 0
    : bpLevelBuyOverflow(rewardsStages, buyIdx, levelPrice, isLevelPurchaseInProgress, buyLevelMsg)
  let children = []
  foreach(idx, stage in rewardsStages)
    children.append(
      stage?.isVip ? emptyStage : mkStageIcon(stage, curStage, levelPrice, isLevelPurchaseInProgress, buyLevelMsg)
      lastIdx == idx ? null : bpLineBetweenLevelIcons(stage, curStage, pointsCurStage, pointsPerStage) )
  return {
    key = "battle_pass_progress_bar"
    pos = [ posFirstElem, 0]
    margin = [-buyLevelBlockOffs, buyOverflow, 0, 0]
    flow = FLOW_HORIZONTAL
    children
  }
}

return bpProgressBar