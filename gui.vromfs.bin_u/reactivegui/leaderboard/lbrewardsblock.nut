from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { lbRewardsBlockWidth, lbTableHeight, lbHeaderRowHeight, prizeIcons,
  rewardStyle, lbRewardRowPadding, lbRewardsGap, getRowBgColor
} = require("lbStyle.nut")
let { localPlayerColor } = require("%rGui/style/stdColors.nut")
let { curLbRewards } = require("lbRewardsState.nut")
let { lbMyPlace, lbTotalPlaces } = require("lbState.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { mkRewardsPreview } = require("%rGui/quests/rewardsComps.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { modalWndBg, modalWndHeaderBg } = require("%rGui/components/modalWnd.nut")
let { boxSize } = rewardStyle


let prizeTextSlots = 2
let defTxtColor = 0xFFD8D8D8
let prizeIconSize = evenPx(60)
let MAX_REWARDS_SLOTS_COUNT = 3

let mkPrizeInfo = @(rType, progress, idx, isReady) {
  size = [prizeTextSlots * boxSize, SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    {
      size = [prizeIconSize, prizeIconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = true
      image = idx not in prizeIcons ? null
        : Picture($"ui/gameuiskin#{prizeIcons[idx]}:{prizeIconSize}:{prizeIconSize}:P")
    }
    @() {
      watch = isReady
      size = FLEX_H
      rendObj = ROBJ_TEXT
      behavior = Behaviors.Marquee
      speed = hdpx(30)
      delay = defMarqueeDelay
      halign = ALIGN_CENTER
      text = progress == -1 || (progress >= 100 && rType == "tillPercent") ? loc("lb/condition/any")
        : loc("lb/condition/topN", { value = rType == "tillPercent" ? $"{progress}%" : progress })
      color = isReady.get() ? localPlayerColor : defTxtColor
    }.__update(fontTiny)
  ]
}

function mkIsReady(rewardInfo) {
  let { rType, progress } = rewardInfo
  return Computed(@() lbMyPlace.get() < 0 ? false
    : progress == -1 ? true
    : rType == "tillPlaces" ? progress >= lbMyPlace.get()
    : rType == "tillPercent" && lbTotalPlaces.get() > 0 ? progress >= 100.0 * (lbMyPlace.get() - 1) / lbTotalPlaces.get()
    : false)
}

function mkRewardRow(rewardInfo, idx) {
  let { rType, progress, rewards } = rewardInfo
  local rewardsViewInfo = []
  foreach (id, count in rewards) {
    let reward = serverConfigs.get()?.userstatRewards[id]
    rewardsViewInfo.extend(getRewardsViewInfo(reward, count))
  }
  rewardsViewInfo = rewardsViewInfo.filter(@(r) r.rType != "medal")
  rewardsViewInfo.sort(sortRewardsViewInfo)

  let isReady = mkIsReady(rewardInfo)

  return @() {
    watch = isReady
    size = flex()
    maxHeight = boxSize + lbRewardRowPadding * 2
    padding = lbRewardRowPadding
    rendObj = ROBJ_SOLID
    color = getRowBgColor(idx % 2, isReady.get())
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      mkPrizeInfo(rType, progress, idx, isReady)
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        halign = ALIGN_RIGHT
        gap = lbRewardsGap
        children = mkRewardsPreview(rewardsViewInfo, false, MAX_REWARDS_SLOTS_COUNT, rewardStyle)
      }
    ]
  }
}

function rewardsList(rewards) {
  let isReady = rewards.len() == 0 ? Watched(false) : mkIsReady(rewards.top())
  return @() {
    watch = isReady
    size = flex()
    rendObj = ROBJ_SOLID
    flow = FLOW_VERTICAL
    color = getRowBgColor(!(rewards.len() % 2), isReady.get())
    children = rewards.map(mkRewardRow)
  }
}

return modalWndBg.__merge({
  size = [lbRewardsBlockWidth, lbTableHeight]
  key = {}
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
  children = [
    modalWndHeaderBg.__merge({
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
    @() {
      watch = curLbRewards
      size = flex()
      children = rewardsList(curLbRewards.get())
    }
  ]
  animations = wndSwitchAnim
})
