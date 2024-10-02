from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { lbRewardsBlockWidth, lbRewardRowHeight, lbTableHeight, lbHeaderRowHeight,
  prizeIcons, rewardStyle, lbRewardsPerRow,
  lbRewardRowPadding, lbRewardsGap, getRowBgColor
} = require("lbStyle.nut")
let { localPlayerColor } = require("%rGui/style/stdColors.nut")
let { curLbRewards } = require("lbRewardsState.nut")
let { lbMyPlace, lbTotalPlaces } = require("lbState.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { bgMessage, bgHeader } = require("%rGui/style/backgrounds.nut")
let { boxSize } = rewardStyle
let { rewardPrizePlateCtors, isPrizeTicket } = require("%rGui/rewards/rewardPrizeView.nut")
let prizeTextSlots = 2
let defTxtColor = 0xFFD8D8D8
let prizeIconSize = evenPx(70)

let mkPrizeInfo = @(rType, progress, idx, isReady) {
  size = [prizeTextSlots * (boxSize + lbRewardsGap) - lbRewardsGap, boxSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    {
      size = [prizeIconSize, prizeIconSize]
      rendObj = ROBJ_IMAGE
      image = idx not in prizeIcons ? null
        : Picture($"ui/gameuiskin#{prizeIcons[idx]}:{prizeIconSize}:{prizeIconSize}:P")
    }
    @() {
      watch = isReady
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = progress == -1 || (progress >= 100 && rType == "tillPercent") ? loc("lb/condition/any")
        : loc("lb/condition/topN", { value = rType == "tillPercent" ? $"{progress}%" : progress })
      color = isReady.value ? localPlayerColor : defTxtColor
    }.__update(fontTiny)
  ]
}

function mkIsReady(rewardInfo) {
  let { rType, progress } = rewardInfo
  return Computed(@() lbMyPlace.value < 0 ? false
    : progress == -1 ? true
    : rType == "tillPlaces" ? progress >= lbMyPlace.value
    : rType == "tillPercent" && lbTotalPlaces.value > 0 ? progress >= 100.0 * (lbMyPlace.value - 1) / lbTotalPlaces.value
    : false)
}

function mkRewardRow(rewardInfo, idx) {
  let { rType, progress, rewards } = rewardInfo
  local rewardsViewInfo = []
  foreach (id, count in rewards) {
    let reward = serverConfigs.value.userstatRewards?[id]
    rewardsViewInfo.extend(getRewardsViewInfo(reward, count))
  }
  rewardsViewInfo = rewardsViewInfo.filter(@(r) r.rType != "medal")
  rewardsViewInfo.sort(sortRewardsViewInfo)

  let totalRewardSlots = rewardsViewInfo.reduce(@(res, r) res + r.slots, 0)
  let totalRows = ceil((prizeTextSlots + totalRewardSlots).tofloat() / lbRewardsPerRow).tointeger()
  let minRewardsInRow = totalRewardSlots / totalRows

  let isReady = mkIsReady(rewardInfo)
  let rows = [{
    leftSlots = lbRewardsPerRow - prizeTextSlots,
    rewardSlots = min(minRewardsInRow, lbRewardsPerRow - prizeTextSlots)
    children = [mkPrizeInfo(rType, progress, idx, isReady)]
  }]

  local extraHeight = 0

  foreach(rInfo in rewardsViewInfo) {
    let comp = !isPrizeTicket(rInfo) ? mkRewardPlate(rInfo, rewardStyle)
      : rewardPrizePlateCtors[rInfo.rType].ctor(rInfo.id, rewardStyle)
    local row = rows.findvalue(@(r, i) r.rewardSlots >= rInfo.slots || (i + 1) == totalRows)
    if(isPrizeTicket(rInfo))
      extraHeight += rewardPrizePlateCtors?[rInfo.rType].extraSize ?? 0
    if (row == null) {
      rows.append({
        leftSlots = lbRewardsPerRow - rInfo.slots
        rewardSlots = minRewardsInRow - rInfo.slots
        children = [comp]
      })
      continue
    }
    row.leftSlots -= rInfo.slots
    row.rewardSlots -= rInfo.slots
    row.children.append(comp)
  }

  foreach(i, row in rows)
    if (row.leftSlots > 0)
      row.children.insert(i == 0 ? 1 : 0,
        { size = [flex(), boxSize] })

  return @() {
    watch = isReady
    size = [flex(), lbRewardRowHeight * rows.len() - lbRewardRowPadding * (rows.len() - 1) + extraHeight]
    padding = lbRewardRowPadding
    rendObj = ROBJ_SOLID
    color = getRowBgColor(idx % 2, isReady.value)
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = lbRewardRowPadding
    children = rows.map(@(row) {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = lbRewardsGap
      valign = ALIGN_CENTER
      children = row.children
    })
  }
}

function mkEmptyLastRow(rewards) {
  let isReady = rewards.len() == 0 ? Watched(false) : mkIsReady(rewards.top())
  return @() {
    watch = isReady
    size = flex()
    rendObj = ROBJ_SOLID
    color = getRowBgColor(!(rewards.len() % 2), isReady.value)
  }
}

let rewardsList = @() {
  watch = curLbRewards
  size = flex()
  flow = FLOW_VERTICAL
  children = curLbRewards.value.map(mkRewardRow)
    .append(mkEmptyLastRow(curLbRewards.value))
}

return bgMessage.__merge({
  size = [lbRewardsBlockWidth, lbTableHeight]
  key = {}
  flow = FLOW_VERTICAL
  children = [
    bgHeader.__merge({
      size = [flex(), lbHeaderRowHeight]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("lb/seasonRewards")
          color = 0xFFD8D8D8
        }.__update(fontTiny)
        infoTooltipButton(@() loc("lb/seasonRewards/desc"), { halign = ALIGN_LEFT })
      ]
    })
    {
      size = flex()
      children = rewardsList
    }
  ]
  animations = wndSwitchAnim
})