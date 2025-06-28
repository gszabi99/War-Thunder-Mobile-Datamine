from "%globalsDarg/darg_library.nut" import *
let { playerExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let { mkResearchProgressLine } = require("%rGui/debriefing/levelProgressLine.nut")
let { mkTotalRewardCountsCampaign } = require("%rGui/debriefing/totalRewardCounts.nut")
let { getLevelUnlockPlateAnimTime, mkLevelUnlockPlatesContainer, mkDebrPlateUnit
} = require("%rGui/debriefing/debrLevelUnlockPlates.nut")

let researchProgressAnimStartTime = 0.0
let researchUnlocksAnimStartTime = 1.0
let rewardsAnimStartTime = 0.5

function getUnitResearchInfo(debrData) {
  local totalExpLeft = debrData?.reward.playerExp.totalExp ?? 0
  let { exp = 0, reqExp = 0, unit = null } = debrData?.researchingUnit
  if (totalExpLeft <= 0 || reqExp <= 0 || unit == null)
    return null
  let addExp = clamp(totalExpLeft, 0, max(0, reqExp - exp))
  return {
    unit
    exp
    reqExp
    addExp
    isUnlocked = addExp > 0 && reqExp <= (exp + totalExpLeft)
  }
}

function mkResearchUnlockPlates(unitResearchInfo, delay) {
  if (unitResearchInfo == null)
    return { researchUnlocksAnimTime = 0, researchUnlocksComp = null }
  let { unit, isUnlocked } = unitResearchInfo
  return {
    researchUnlocksAnimTime = getLevelUnlockPlateAnimTime(1)
    researchUnlocksComp = mkDebrPlateUnit(unit, isUnlocked, delay, false)
  }
}

function mkDebriefingWndTabResearch(debrData, params) {
  let { totalRewardCountsComp, totalRewardsShowTime, btnTryPremium
  } = mkTotalRewardCountsCampaign(debrData, rewardsAnimStartTime)
  let unitResearchInfo = getUnitResearchInfo(debrData)
  if (totalRewardCountsComp == null || unitResearchInfo == null)
    return null
  let { researchProgressLineComp, researchProgressLineAnimTime } = mkResearchProgressLine(debrData, unitResearchInfo
    loc("gamercard/researchProgress/header"), loc("gamercard/researchProgress/desc"),
    researchProgressAnimStartTime, playerExpColor)
  let { researchUnlocksComp, researchUnlocksAnimTime } = mkResearchUnlockPlates(unitResearchInfo, researchUnlocksAnimStartTime)

  let { needBtnCampaign } = params
  let timeShow = max(
      researchProgressAnimStartTime + researchProgressLineAnimTime,
      researchUnlocksAnimStartTime + researchUnlocksAnimTime,
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
            size = const [hdpx(1600), flex()]
            halign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            children = [
              researchProgressLineComp
              {
                size = flex()
                flow = FLOW_HORIZONTAL
                gap = hdpx(100)
                children = [
                  totalRewardCountsComp.__update({ pos = [0, hdpx(145)] })
                  mkLevelUnlockPlatesContainer(researchUnlocksComp)
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

return mkDebriefingWndTabResearch
