from "%globalsDarg/darg_library.nut" import *
let { getPlatoonName, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { sortUnits } = require("%rGui/unit/unitUtils.nut")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let { mkLevelProgressLine } = require("%rGui/debriefing/levelProgressLine.nut")
let { mkTotalRewardCountsUnit } = require("%rGui/debriefing/totalRewardCounts.nut")
let { getBestUnitName, getUnit, getUnitRewards, getLevelProgress, sortUnitMods } = require("%rGui/debriefing/debrUtils.nut")
let { getLevelUnlockPlateAnimTime, mkLevelUnlockPlatesContainer,
  mkDebrPlateUnit, mkDebrPlateMod, mkDebrPlatePoints
} = require("%rGui/debriefing/debrLevelUnlockPlates.nut")

let levelProgressAnimStartTime = 0.0
let levelUnlocksAnimStartTime = 1.0
let rewardsAnimStartTime = 0.5

function mkUnitLevelUnlockPlates(unit, debrData, delay) {
  let res = {
    levelUnlocksAnimTime = 0
    levelUnlocksComps = null
  }
  if (unit == null)
    return res

  let { items = {} } = debrData
  let unitExp = getUnitRewards(unit?.name, debrData)?.exp
  let { prevLevel, unlockedLevel } = getLevelProgress(unit, unitExp)
  let startLevel = prevLevel + 1
  let endLevel = max(startLevel, unlockedLevel)
  let { lockedUnits = [], modPresetCfg = {}, levelsSp = {} } = unit
  let spLevels = levelsSp?.levels ?? []

  let list = []
  for (local l = startLevel; l <= endLevel; l++) {
    let isUnlocked = l <= unlockedLevel
    
    let units = lockedUnits.filter(@(v) v.reqLevel == l)
      .map(@(v) unit.__merge(v, { platoonUnits = [], lockedUnits = [] }))
    units.sort(sortUnits)
    list.extend(units.map(@(v) { isUnlocked, data = v, ctor = mkDebrPlateUnit }))
    
    let modsList = modPresetCfg
      .map(@(mod, name) mod.__merge({ name }))
      .values()
      .filter(@(mod) mod?.reqLevel == l && !mod?.isHidden && (mod.name not in items))
    modsList.sort(sortUnitMods)
    list.extend(modsList.map(@(v) { isUnlocked, data = v, ctor = mkDebrPlateMod }))
    
    let sp = spLevels?[l - 1] ?? 0
    if (sp > 0) {
      let data = { sp, reqLevel = l, name = $"sp{l}" }
      list.append({ isUnlocked, data, ctor = mkDebrPlatePoints })
    }
  }

  let total = list.len()
  let itemTime = getLevelUnlockPlateAnimTime(total)
  res.levelUnlocksAnimTime = total * itemTime
  res.levelUnlocksComps = list.map(function(v, idx) {
    let { ctor, data, isUnlocked } = v
    let unlockDelay = delay + (itemTime * idx)
    return ctor(data, isUnlocked, unlockDelay)
  })
  return res
}

function mkDebriefingWndTabUnit(debrData, params) {
  let { campaign = "" } = debrData
  let unitName = getBestUnitName(debrData)
  let unit = getUnit(unitName, debrData)
  if (unit == null)
    return null

  let isPlatoon = (unit?.platoonUnits.len() ?? 0) != 0 || (unit?.lockedUnits.len() ?? 0) != 0
  let unitNameLoc = isPlatoon ? getPlatoonName(unitName, loc) : loc(getUnitLocId(unitName))

  let { totalRewardCountsComp, totalRewardsShowTime, btnTryPremium
  } = mkTotalRewardCountsUnit(debrData, rewardsAnimStartTime)
  if (totalRewardCountsComp == null)
    return null

  let unitExp = getUnitRewards(unit?.name, debrData)?.exp
  let { levelProgressLineComp, levelProgressLineAnimTime } = mkLevelProgressLine(unit, unitExp,
    unitNameLoc, loc(getCampaignPresentation(campaign).debrUnitLevelDescLocId),
    levelProgressAnimStartTime,  unitExpColor)
  let { levelUnlocksComps, levelUnlocksAnimTime } = mkUnitLevelUnlockPlates(unit, debrData, levelUnlocksAnimStartTime)

  let { needBtnUnit = true } = params
  let timeShow = max(
      levelProgressAnimStartTime + levelProgressLineAnimTime,
      levelUnlocksAnimStartTime + levelUnlocksAnimTime,
      rewardsAnimStartTime + totalRewardsShowTime
    ) + (needBtnUnit ? buttonsShowTime : 0)

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
    forceStopAnim = params.needBtnUnit
  }
}

return mkDebriefingWndTabUnit
