from "%globalsDarg/darg_library.nut" import *
let { can_write_replays } = require("%appGlobals/permissions.nut")
let { makeSideScroll } = require("%rGui/components/scrollbar.nut")
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { mkDebriefingStats } = require("mkDebriefingStats.nut")
let { hasUnsavedReplay } = require("%rGui/replay/lastReplayState.nut")
let saveReplayWindow = require("%rGui/replay/saveReplayWindow.nut")
let { mkMissionResultTitle, missionResultTitleAnimTime } = require("%rGui/debriefing/missionResultTitle.nut")
let achievementsBlock = require("achievementsBlock.nut")
let mkDebrQuestsProgress = require("mkDebrQuestsProgress.nut")
let { mkTotalRewardCountsScores } = require("%rGui/debriefing/totalRewardCounts.nut")

let rewardsAnimStartTime = 0.5
let questsAnimStartTime = 0.5

let btnSaveReplay = @() {
  watch = [can_write_replays, hasUnsavedReplay]
  children = !can_write_replays.get() || !hasUnsavedReplay.get() ? null
    : translucentButton("ui/gameuiskin#icon_save.svg", "", saveReplayWindow)
}

function mkDebriefingWndTabScores(debrData, _params) {
  if (debrData == null)
    return null

  let achievementsAnimStartTime = missionResultTitleAnimTime / 2
  let { achievementsAnimTime, achievementsComp } = achievementsBlock(debrData, achievementsAnimStartTime)
  let statsAnimStartTime = achievementsAnimStartTime + achievementsAnimTime
  let { statsAnimEndTime, debriefingStats } = mkDebriefingStats(debrData, statsAnimStartTime)

  let { totalRewardCountsComp, totalRewardsShowTime, btnTryPremium
  } = mkTotalRewardCountsScores(debrData, rewardsAnimStartTime)

  let { questsProgressComps, questsProgressShowTime } = mkDebrQuestsProgress(debrData, questsAnimStartTime)

  let timeShow = max(
    statsAnimEndTime,
    rewardsAnimStartTime + totalRewardsShowTime,
    questsAnimStartTime + questsProgressShowTime
  )

  if (achievementsComp == null && totalRewardCountsComp == null && debriefingStats == null && questsProgressComps == null)
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
            size = const [hdpx(1600), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = hdpx(100)
            children = [
              totalRewardCountsComp
              debriefingStats
            ]
          }
          questsProgressComps == null ? null : makeSideScroll({
            size = FLEX_H
            halign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            gap = hdpx(8)
            children = questsProgressComps
          })
        ]
      }
      {
        vplace = ALIGN_BOTTOM
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        gap = hdpx(40)
        children = [
          btnTryPremium
          btnSaveReplay
        ]
      }
    ]
  }

  return {
    comp
    timeShow
    forceStopAnim = false
  }
}

return mkDebriefingWndTabScores
