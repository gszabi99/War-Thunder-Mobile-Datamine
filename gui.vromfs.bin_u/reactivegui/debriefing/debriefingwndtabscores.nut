from "%globalsDarg/darg_library.nut" import *
let { can_write_replays } = require("%appGlobals/permissions.nut")
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { mkDebriefingStats } = require("mkDebriefingStats.nut")
let { hasUnsavedReplay } = require("%rGui/replay/lastReplayState.nut")
let saveReplayWindow = require("%rGui/replay/saveReplayWindow.nut")
let { mkMissionResultTitle, missionResultTitleAnimTime } = require("%rGui/debriefing/missionResultTitle.nut")
let achievementsBlock = require("achievementsBlock.nut")
let { mkTotalRewardCountsScores } = require("%rGui/debriefing/totalRewardCounts.nut")

let deltaStartTimeLevelReward = 1.0

let btnSaveReplay = @() {
  watch = [can_write_replays, hasUnsavedReplay]
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  children = !can_write_replays.get() || !hasUnsavedReplay.get() ? null
    : translucentButton("ui/gameuiskin#icon_save.svg", "", saveReplayWindow)
}

let function mkDebriefingWndTabScores(debrData, _params) {
  if (debrData == null)
    return null

  let achievementsAnimStartTime = missionResultTitleAnimTime / 2
  let { achievementsAnimTime, achievementsComp } = achievementsBlock(debrData, achievementsAnimStartTime)
  let statsAnimStartTime = achievementsAnimStartTime + achievementsAnimTime
  let { statsAnimEndTime, debriefingStats } = mkDebriefingStats(debrData, statsAnimStartTime)
  let rewardsStartTime = statsAnimEndTime + deltaStartTimeLevelReward

  let { totalRewardCountsComp, totalRewardsShowTime } = mkTotalRewardCountsScores(debrData, [], rewardsStartTime)
  let timeShow = rewardsStartTime + totalRewardsShowTime

  if (achievementsComp == null && totalRewardCountsComp == null && debriefingStats == null)
    return null

  let comp = {
    size = flex()
    children = [
      {
        size = flex()
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          mkMissionResultTitle(debrData, true)
          achievementsComp
          {
            size = [hdpx(1600), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = hdpx(100)
            children = [
              totalRewardCountsComp
              debriefingStats
            ]
          }
        ]
      }
      btnSaveReplay
    ]
  }

  return {
    comp
    timeShow
  }
}

return mkDebriefingWndTabScores
