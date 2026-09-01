from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/levelBlockPkg.nut" import playerExpColor
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/debriefing/debrLevelUnlockPlates.nut" import getLevelUnlockPlateAnimTime, mkLevelUnlockPlatesContainer,
  mkDebrPlateUnit
from "%rGui/debriefing/debriefingWndConsts.nut" import buttonsShowTime
from "%rGui/debriefing/levelProgressLine.nut" import mkResearchProgressLine
from "%rGui/debriefing/missionResultTitle.nut" import mkMissionResultTitle
from "%rGui/debriefing/totalRewardCounts.nut" import mkTotalRewardCountsCampaign


const researchProgressAnimStartTime = 0.0
const researchUnlocksAnimStartTime = 1.0
const rewardsAnimStartTime = 0.5

function getUnitResearchInfo(debrData) {
  local totalExpLeft = (debrData?.reward.playerExp.totalExp ?? 0) + (debrData?.adsBonuses.expDif ?? 0) + (debrData?.subsBonuses.expDif ?? 0)
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
    size = FLEX
    children = [
      {
        size = FLEX
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          mkMissionResultTitle(debrData, false)
          {
            size = const [SIZE_TO_CONTENT, FLEX]
            halign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            children = [
              researchProgressLineComp
              {
                size = FLEX
                gap = hdpx(120)
                children = [
                  panelBg.__merge(totalRewardCountsComp.__update({
                    size = SIZE_TO_CONTENT,
                    pos = const [hdpx(85), hdpx(145)]
                  }))
                  mkLevelUnlockPlatesContainer(researchUnlocksComp).__update({ pos = const [hdpx(1000), 0] })
                ]
              }
            ]
          }
        ]
      }
      {
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_RIGHT
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
