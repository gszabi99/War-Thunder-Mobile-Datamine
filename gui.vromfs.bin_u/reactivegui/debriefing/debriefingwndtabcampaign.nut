from "%globalsDarg/darg_library.nut" import *
let { buttonsShowTime, tabFinalPauseTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let { mkLevelProgressLine, maxLevelProgressAnimTime } = require("%rGui/debriefing/levelProgressLine.nut")
let { mkTotalRewardCountsCampaign } = require("%rGui/debriefing/totalRewardCounts.nut")

let deltaStartTimeLevelReward = maxLevelProgressAnimTime / 2

let function mkPlayerLevelLine(debrData, animStartTime) {
  let { reward = {}, player = {} } = debrData
  let { playerExp = {} } = reward
  return {
    size = [flex(), SIZE_TO_CONTENT]
    padding = [hdpx(22), 0, 0, 0]
    halign = ALIGN_CENTER
    children = mkLevelProgressLine(player, playerExp, loc("debriefing/playerExp"), animStartTime)
  }
}

let function mkDebriefingWndTabCampaign(debrData, rewardsInfo, params) {
  if (rewardsInfo.totalPlayerExp == 0)
    return null

  let rewardsStartTime = deltaStartTimeLevelReward
  let { totalRewardCountsComp, totalRewardsShowTime } = mkTotalRewardCountsCampaign(rewardsInfo, [], rewardsStartTime)

  let { needBtnCampaign } = params
  let timeShow = rewardsStartTime + totalRewardsShowTime + (needBtnCampaign ? buttonsShowTime : 0) + tabFinalPauseTime

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
          mkPlayerLevelLine(debrData, 0)
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
