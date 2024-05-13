from "%globalsDarg/darg_library.nut" import *
let { playerExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { sortUnits } = require("%rGui/unit/unitUtils.nut")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let mkLevelProgressLine = require("%rGui/debriefing/levelProgressLine.nut")
let { mkTotalRewardCountsCampaign } = require("%rGui/debriefing/totalRewardCounts.nut")
let { getLevelProgress } = require("%rGui/debriefing/debrUtils.nut")
let { getLevelUnlockPlateAnimTime, mkLevelUnlockPlatesContainer, mkDebrPlateUnit
} = require("%rGui/debriefing/debrLevelUnlockPlates.nut")

let levelProgressAnimStartTime = 0.0
let levelUnlocksAnimStartTime = 1.0
let rewardsAnimStartTime = 0.5

function mkPlayerLevelUnlockPlates(debrData, delay) {
  let { reward = {}, player = {}, nextLevelUnits = {} } = debrData
  let { playerExp = {} } = reward

  let { prevLevel, unlockedLevel } = getLevelProgress(player, playerExp)

  let nextLevel = prevLevel + 1
  let isUnlocked = nextLevel == unlockedLevel
  let units = nextLevelUnits.values()
  units.sort(sortUnits)
  let total = units.len()
  let itemTime = getLevelUnlockPlateAnimTime(total)
  return {
    levelUnlocksAnimTime = total * itemTime
    levelUnlocksComps = units.len() == 0 ? null : units.map(function(unit, idx) {
      let unlockDelay = delay + (itemTime * idx)
      return mkDebrPlateUnit(unit, isUnlocked, unlockDelay, true)
    })
  }
}

function mkDebriefingWndTabCampaign(debrData, params) {
  let { totalRewardCountsComp, totalRewardsShowTime, btnTryPremium
  } = mkTotalRewardCountsCampaign(debrData, rewardsAnimStartTime)
  let { reward = {}, player = {}, campaign = "" } = debrData
  if (totalRewardCountsComp == null || player?.isLastLevel)
    return null
  let { playerExp = {} } = reward
  let { levelProgressLineComp, levelProgressLineAnimTime } = mkLevelProgressLine(player, playerExp,
    loc($"gamercard/levelCamp/header/{campaign}"), loc("gamercard/levelCamp/desc"),
    levelProgressAnimStartTime, playerExpColor)
  let { levelUnlocksComps, levelUnlocksAnimTime } = mkPlayerLevelUnlockPlates(debrData, levelUnlocksAnimStartTime)

  let { needBtnCampaign } = params
  let timeShow = max(
      levelProgressAnimStartTime + levelProgressLineAnimTime,
      levelUnlocksAnimStartTime + levelUnlocksAnimTime,
      rewardsAnimStartTime + totalRewardsShowTime
    ) + (needBtnCampaign ? buttonsShowTime : 0)

  let comp = {
    size = flex()
    children = [
      {
        size = flex()
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          mkMissionResultTitle(debrData, false)
          {
            size = [hdpx(1600), flex()]
            halign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            children = [
              levelProgressLineComp
              {
                size = flex()
                flow = FLOW_HORIZONTAL
                gap = hdpx(100)
                children = [
                  totalRewardCountsComp.__update({ pos = [0, hdpx(145)] })
                  mkLevelUnlockPlatesContainer(levelUnlocksComps)
                ]
              }
            ]
          }
        ]
      }
      {
        vplace = ALIGN_BOTTOM
        children = btnTryPremium
      }
    ]
  }

  return {
    comp
    timeShow
    forceStopAnim = params.needBtnCampaign
  }
}

return mkDebriefingWndTabCampaign
