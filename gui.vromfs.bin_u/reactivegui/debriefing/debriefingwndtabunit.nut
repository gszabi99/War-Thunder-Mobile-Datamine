from "%globalsDarg/darg_library.nut" import *
let { getUnitPresentation, getPlatoonName } = require("%appGlobals/unitPresentation.nut")
let { unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitBg, mkUnitImage, mkUnitTexts,
  mkPlatoonBgPlates, platoonPlatesGap, mkPlatoonPlateFrame
} = require("%rGui/unit/components/unitPlateComp.nut")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let mkLevelProgressLine = require("%rGui/debriefing/levelProgressLine.nut")
let { mkTotalRewardCountsUnit } = require("%rGui/debriefing/totalRewardCounts.nut")

let levelProgressAnimStartTime = 0.0
let rewardsAnimStartTime = 0.5

let mkPlayerLevelLineHolder = @(children) children == null ? null : {
  size = [flex(), SIZE_TO_CONTENT]
  padding = [hdpx(22), 0, 0, 0]
  halign = ALIGN_CENTER
  children
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

let function mkDebriefingWndTabUnit(debrData, params) {
  let { reward = {}, unit = null, campaign = "" } = debrData
  if (unit == null)
    return null

  let { totalRewardCountsComp, totalRewardsShowTime } = mkTotalRewardCountsUnit(debrData, rewardsAnimStartTime)
  if (totalRewardCountsComp == null)
    return null

  let { unitExp = {} } = reward
  let { levelProgressLineComp, levelProgressLineAnimTime } = mkLevelProgressLine(unit, unitExp,
    loc(campaign == "tanks" ? "debriefing/platoonExp" : "debriefing/shipExp"), levelProgressAnimStartTime,  unitExpColor)

  let { needBtnUnit = true } = params
  let timeShow = max(levelProgressAnimStartTime + levelProgressLineAnimTime, rewardsAnimStartTime + totalRewardsShowTime)
    + (needBtnUnit ? buttonsShowTime : 0)

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
              mkPlayerLevelLineHolder(levelProgressLineComp)
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
