from "%globalsDarg/darg_library.nut" import *
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let mkLevelProgressLine = require("%rGui/debriefing/levelProgressLine.nut")
let { mkTotalRewardCountsCampaign } = require("%rGui/debriefing/totalRewardCounts.nut")

let levelProgressAnimStartTime = 0.0
let rewardsAnimStartTime = 0.5

let mkPlayerLevelLineHolder = @(children) children == null ? null : {
  size = [flex(), SIZE_TO_CONTENT]
  padding = [hdpx(22), 0, 0, 0]
  halign = ALIGN_CENTER
  children
}

let function mkDebriefingWndTabCampaign(debrData, params) {
  let { totalRewardCountsComp, totalRewardsShowTime } = mkTotalRewardCountsCampaign(debrData, rewardsAnimStartTime)
  if (totalRewardCountsComp == null)
    return null

  let { reward = {}, player = {} } = debrData
  let { playerExp = {} } = reward
  let { levelProgressLineComp, levelProgressLineAnimTime } = mkLevelProgressLine(player, playerExp,
    loc("debriefing/playerExp"), levelProgressAnimStartTime)

  let { needBtnCampaign } = params
  let timeShow = max(levelProgressAnimStartTime + levelProgressLineAnimTime, rewardsAnimStartTime + totalRewardsShowTime)
    + (needBtnCampaign ? buttonsShowTime : 0)

  let comp = {
    size = flex()
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      mkMissionResultTitle(debrData, false)
      {
        size = [hdpx(1600), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = hdpx(100)
        children = [
          totalRewardCountsComp
          mkPlayerLevelLineHolder(levelProgressLineComp)
        ]
      }
    ]
  }

  return {
    comp
    timeShow
  }
}

return mkDebriefingWndTabCampaign
