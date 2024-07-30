from "%globalsDarg/darg_library.nut" import *
let { unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let { getUnitsSet, getUnitRewards, isUnitReceiveLevel, getLevelProgress, sortUnitMods } = require("%rGui/debriefing/debrUtils.nut")
let { mkUnitPlateWithLevelProgress } = require("%rGui/debriefing/mkUnitPlateWithLevelProgress.nut")
let { getLevelUnlockLineAnimTime, mkLevelUnlockLinesContainer, mkDebrLineMod, mkDebrLinePoints
} = require("%rGui/debriefing/debrLevelUnlockLines.nut")

let levelProgressAnimStartTime = 0.0
let levelUnlocksAnimStartTime = 1.0

let columnWidth = hdpx(350)
let columnGap = hdpx(50)

function mkUnitLevelUnlockLines(unit, debrData, delay) {
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
  let { modPresetCfg = {}, levelsSp = {} } = unit
  let spLevels = levelsSp?.levels ?? []

  let list = []
  for (local l = startLevel; l <= endLevel; l++) {
    let isUnlocked = l <= unlockedLevel
    // Mods
    let modsList = modPresetCfg
      .map(@(mod, name) mod.__merge({ name }))
      .values()
      .filter(@(mod) mod?.reqLevel == l && !mod?.isHidden && (mod.name not in items))
    modsList.sort(sortUnitMods)
    list.extend(modsList.map(@(v) { isUnlocked, data = v, ctor = mkDebrLineMod }))
    // Points
    let sp = spLevels?[l - 1] ?? 0
    if (sp > 0) {
      let data = { sp, reqLevel = l, name = $"sp{l}" }
      list.append({ isUnlocked, data, ctor = mkDebrLinePoints })
    }
  }

  let total = list.len()
  let itemTime = getLevelUnlockLineAnimTime(total)
  res.levelUnlocksAnimTime = total * itemTime
  res.levelUnlocksComps = list.map(function(v, idx) {
    let { ctor, data, isUnlocked } = v
    let unlockDelay = delay + (itemTime * idx)
    return ctor(data, isUnlocked, unlockDelay)
  })
  return res
}

function mkUnitColumn(unit, debrData) {
  if (unit == null)
    return null

  let unitExp = getUnitRewards(unit?.name, debrData)?.exp
  let { unitPlateWithLevelProgressComp, levelProgressAnimTime } = mkUnitPlateWithLevelProgress(unit, unitExp, levelProgressAnimStartTime, unitExpColor)
  let { levelUnlocksComps, levelUnlocksAnimTime } = mkUnitLevelUnlockLines(unit, debrData, levelUnlocksAnimStartTime)
  let levelUnlockLines = mkLevelUnlockLinesContainer(levelUnlocksComps)

  let columnShowTime = max(
      levelProgressAnimStartTime + levelProgressAnimTime,
      levelUnlocksAnimStartTime + levelUnlocksAnimTime
    )

  let columnComp = {
    size = [columnWidth, flex()]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      unitPlateWithLevelProgressComp
      levelUnlockLines
    ]
  }

  return {
    columnComp
    columnShowTime
  }
}

function mkDebriefingWndTabUnitsSet(debrData, params) {
  let units = getUnitsSet(debrData)

  local hasAnyUnitRewards = false
  foreach (unit in units) {
    hasAnyUnitRewards = (getUnitRewards(unit?.name, debrData)?.exp.totalExp ?? 0) > 0
    if (hasAnyUnitRewards)
      break
  }
  if (!hasAnyUnitRewards)
    return null

  local hasAnyUnitLevelUps = false
  foreach (unit in units) {
    hasAnyUnitLevelUps = isUnitReceiveLevel(unit?.name, debrData)
    if (hasAnyUnitLevelUps)
      break
  }

  let columnsData = units.map(@(u) mkUnitColumn(u, debrData))

  let { needBtnUnit = true } = params
  let timeShow = columnsData.reduce(@(res, v) max(res, v.columnShowTime), 0) + (needBtnUnit ? buttonsShowTime : 0)

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
            flow = FLOW_HORIZONTAL
            gap = columnGap
            children = columnsData.map(@(v) v.columnComp)
          }
        ]
      }
    ]
  }

  return {
    comp
    timeShow
    forceStopAnim = params.needBtnUnit || hasAnyUnitLevelUps
  }
}

return mkDebriefingWndTabUnitsSet
