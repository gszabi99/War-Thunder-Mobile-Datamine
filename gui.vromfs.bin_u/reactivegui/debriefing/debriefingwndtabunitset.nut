from "%globalsDarg/darg_library.nut" import *
let { unitExpColor, slotExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let { getUnitsSet, getUnitRewards, getSlotExpByUnit, getSlotLevelCfg, getLevelProgress,
  getNextUnitLevelWithRewards, getSlotOrUnitLevelUnlockRewards, sortUnitMods
} = require("%rGui/debriefing/debrUtils.nut")
let mkPlateWithLevelProgress = require("%rGui/debriefing/mkPlateWithLevelProgress.nut")
let { getLevelUnlockLineAnimTime, mkLevelUnlockLinesContainer, mkDebrLineMod, mkDebrLineWeapon,
  mkDebrLineAmmo, mkDebrLinePoints
} = require("%rGui/debriefing/debrLevelUnlockLines.nut")

let levelProgressAnimStartTime = 0.0
let levelUnlocksAnimStartTime = 1.0

let columnWidth = hdpx(350)
let columnGap = hdpx(50)

function mkLevelUnlockLines(list, delay) {
  let res = {
    levelUnlocksAnimTime = 0
    levelUnlocksComps = null
  }
  let total = list.len()
  if (total == 0)
    return res
  let itemTime = getLevelUnlockLineAnimTime(total)
  res.levelUnlocksAnimTime = total * itemTime
  res.levelUnlocksComps = list.map(function(v, idx) {
    let { ctor, data, isUnlocked } = v
    let unlockDelay = delay + (itemTime * idx)
    return ctor(data, isUnlocked, unlockDelay)
  })
  return res
}

function mkSlotLevelUnlockLines(unit, debrData, delay) {
  if (unit == null)
    return mkLevelUnlockLines([], delay)

  let slotExp = getSlotExpByUnit(unit?.name, debrData)
  let { levelsSp = {} } = debrData?.slots
  let slotLevelCfg = getSlotLevelCfg(unit, debrData)
  let { prevLevel, unlockedLevel } = getLevelProgress(slotLevelCfg, slotExp)
  let startLevel = prevLevel + 1
  let endLevel = max(startLevel, unlockedLevel)
  let spLevels = levelsSp?.levels ?? []

  let list = []
  for (local l = startLevel; l <= endLevel; l++) {
    let isUnlocked = l <= unlockedLevel
    
    let sp = spLevels?[l - 1] ?? 0
    if (sp > 0) {
      let data = { sp, reqLevel = l, name = $"sp{l}" }
      list.append({ isUnlocked, data, ctor = mkDebrLinePoints })
    }
  }

  return mkLevelUnlockLines(list, delay)
}

function mkUnitLevelUnlockLines(unit, debrData, delay) {
  if (unit == null)
    return mkLevelUnlockLines([], delay)

  let { unitWeaponry = {}, campaign = "" } = debrData
  let unitExp = getUnitRewards(unit?.name, debrData)?.exp
  let { modPresetCfg = {}, levelsExp = [] } = unit
  let { prevLevel, unlockedLevel } = getLevelProgress(unit, unitExp)
  let startLevel = prevLevel + 1
  let endLevel = max(unlockedLevel,
    getNextUnitLevelWithRewards(startLevel, levelsExp.len(), modPresetCfg, unitWeaponry?[unit?.name]))

  let isModsWeapons = campaign == "air"
  let modsMap = modPresetCfg
    .filter(@(mod) !mod?.isHidden)
    .map(@(mod, name) mod.__merge({ name }))
  let weaponsPresetsMap = (unitWeaponry?[unit?.name].weaponPresets ?? {})
    .map(@(w) {
        reqLevel = modsMap?[w?.reqModification].reqLevel
      }.__update(w))
  let ammoForWeaponsMap = {}
  let { ammoForWeapons = {} } = unitWeaponry?[unit?.name]
  foreach (weapon in ammoForWeapons) {
    let { fromUnitTags = {} } = weapon
    foreach (bSetId, b in fromUnitTags) {
      let reqLevel = b?.reqLevel ?? modsMap?[b?.reqModification].reqLevel ?? 0
      ammoForWeaponsMap[bSetId] <- {
        bSetId
        weapon
        reqLevel
        isModsWeapons
        campaign
      }
    }
  }

  let list = []
  for (local l = startLevel; l <= endLevel; l++) {
    let isUnlocked = l <= unlockedLevel
    
    if (!isModsWeapons) {
      let modsList = modsMap
        .filter(@(mod) mod?.reqLevel == l)
        .values()
      modsList.sort(sortUnitMods)
      list.extend(modsList.map(@(v) { isUnlocked, data = v, ctor = mkDebrLineMod }))
    }
    
    let weaponsList = weaponsPresetsMap
      .filter(@(w) w?.reqLevel == l)
      .values()
    list.extend(weaponsList.map(@(v) { isUnlocked, data = v, ctor = mkDebrLineWeapon }))
    
    let ammoList = ammoForWeaponsMap
      .filter(@(w) w?.reqLevel == l)
      .values()
    list.extend(ammoList.map(@(v) { isUnlocked, data = v, ctor = mkDebrLineAmmo }))
  }

  return mkLevelUnlockLines(list, delay)
}

function mkColumn(plateWithLevelProgressComp, levelProgressAnimTime, levelUnlocksComps, levelUnlocksAnimTime) {
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
      plateWithLevelProgressComp
      levelUnlockLines
    ]
  }

  return {
    columnComp
    columnShowTime
  }
}

function mkSlotColumn(unit, debrData) {
  if (unit == null)
    return null
  let slotLevelCfg = getSlotLevelCfg(unit, debrData)
  let slotExp = getSlotExpByUnit(unit?.name, debrData)
  let { plateWithLevelProgressComp, levelProgressAnimTime
  } = mkPlateWithLevelProgress(debrData, slotLevelCfg, slotExp, levelProgressAnimStartTime, slotExpColor)
  let { levelUnlocksComps, levelUnlocksAnimTime } = mkSlotLevelUnlockLines(unit, debrData, levelUnlocksAnimStartTime)
  return mkColumn(plateWithLevelProgressComp, levelProgressAnimTime, levelUnlocksComps, levelUnlocksAnimTime)
}

function mkUnitColumn(unit, debrData) {
  if (unit == null)
    return null
  let unitExp = getUnitRewards(unit?.name, debrData)?.exp
  let { plateWithLevelProgressComp, levelProgressAnimTime
  } = mkPlateWithLevelProgress(debrData, unit, unitExp, levelProgressAnimStartTime, unitExpColor)
  let { levelUnlocksComps, levelUnlocksAnimTime } = mkUnitLevelUnlockLines(unit, debrData, levelUnlocksAnimStartTime)
  return mkColumn(plateWithLevelProgressComp, levelProgressAnimTime, levelUnlocksComps, levelUnlocksAnimTime)
}

function mkDebriefingWndTabUnitsSet(debrData, params) {
  let units = getUnitsSet(debrData)

  local needShow = false
  foreach (unit in units) {
    needShow = (getUnitRewards(unit?.name, debrData)?.exp.totalExp ?? 0) > 0
    if (needShow)
      break
  }
  if (!needShow)
    return null

  let hasAnyLevelUnlockRewards = getSlotOrUnitLevelUnlockRewards(debrData).has

  let slotColumnsData = units.map(@(u) mkSlotColumn(u, debrData))
  let unitColumnsData = units.map(@(u) mkUnitColumn(u, debrData))

  let { needBtnUnit = true } = params
  let timeShow = unitColumnsData.reduce(@(res, v) max(res, v.columnShowTime), 0) + (needBtnUnit ? buttonsShowTime : 0)

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
            flow = FLOW_HORIZONTAL
            gap = columnGap
            children = slotColumnsData.map(@(v) v.columnComp)
          }
          {
            size = const [hdpx(1600), flex()]
            halign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = columnGap
            children = unitColumnsData.map(@(v) v.columnComp)
          }
        ]
      }
    ]
  }

  return {
    comp
    timeShow
    forceStopAnim = params.needBtnUnit || hasAnyLevelUnlockRewards
  }
}

return mkDebriefingWndTabUnitsSet
