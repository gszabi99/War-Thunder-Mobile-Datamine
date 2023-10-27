from "%globalsDarg/darg_library.nut" import *
let { getUnitPresentation, getPlatoonName } = require("%appGlobals/unitPresentation.nut")
let { unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitBg, mkUnitImage, mkUnitTexts,
  mkPlatoonBgPlates, platoonPlatesGap, mkPlatoonPlateFrame
} = require("%rGui/unit/components/unitPlateComp.nut")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let { mkLevelProgressLine, maxLevelProgressAnimTime } = require("%rGui/debriefing/levelProgressLine.nut")
let { mkTotalRewardCountsUnit } = require("%rGui/debriefing/totalRewardCounts.nut")

let deltaStartTimeLevelReward = maxLevelProgressAnimTime / 2

let function mkUnitLevelLine(debrData, animStartTime) {
  let { reward = {}, unit = null, campaign = "" } = debrData
  let { unitExp = {} } = reward
  return unitExp.len() == 0 ? null
    : {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [hdpx(22), 0, 0, 0]
        halign = ALIGN_CENTER
        children = mkLevelProgressLine(unit, unitExp,
          loc(campaign == "tanks" ? "debriefing/platoonExp" : "debriefing/shipExp"),animStartTime,  unitExpColor)
      }
}

let function mkUnitPlate(unit) {
  if (unit == null)
    return null
  let p = getUnitPresentation(unit)
  let platoonUnits = (unit?.platoonUnits ?? []).map(@(u) u.name)
    .extend((unit?.lockedUnits ?? []).map(@(u) u.name))
  let platoonSize = platoonUnits.len()
  let height = platoonSize == 0 ? unitPlateHeight
    : unitPlateHeight + platoonPlatesGap * platoonSize
  return {
    size = [ unitPlateWidth, height ]
    children = {
      size = [ unitPlateWidth, unitPlateHeight ]
      vplace = ALIGN_BOTTOM
      children = platoonSize > 0
        ? [
            mkPlatoonBgPlates(unit, platoonUnits)
            mkUnitBg(unit)
            mkUnitImage(unit)
            mkUnitTexts(unit, getPlatoonName(unit.name, loc))
            mkPlatoonPlateFrame()
          ]
        : [
            mkUnitBg(unit)
            mkUnitImage(unit)
            mkUnitTexts(unit, loc(p.locId))
          ]
    }
  }
}

let function mkDebriefingWndTabUnit(debrData, rewardsInfo, params) {
  let { unit = null } = debrData
  if (unit == null || rewardsInfo.totalUnitExp == 0)
    return null

  let rewardsStartTime = deltaStartTimeLevelReward
  let { totalRewardCountsComp, totalRewardsShowTime } = mkTotalRewardCountsUnit(rewardsInfo, [], rewardsStartTime)

  let { needBtnUnit = true } = params
  let timeShow = rewardsStartTime + totalRewardsShowTime + (needBtnUnit ? buttonsShowTime : 0)

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
          {
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            gap = hdpx(40)
            children = [
              mkUnitLevelLine(debrData, 0)
              mkUnitPlate(unit)
            ]
          }
        ]
      }
    ]
  }

  return {
    comp
    timeShow
  }
}

return mkDebriefingWndTabUnit
