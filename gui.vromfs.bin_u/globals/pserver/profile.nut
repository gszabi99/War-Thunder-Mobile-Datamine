let { deferOnce } = require("dagor.workcycle")
let { Computed, Watched } = require("frp")
let { min, max } = require("math")
let { units, levelInfo, campConfigs, curCampaignSlotUnits } = require("campaign.nut")
let { curUnitInProgress } = require("pServerApi.nut")

let defaultProfileLevelInfo = {
  exp = 0
  level = 1
  starLevel = 0
  historyStarLevel = 0
  seenLevel = 1
  nextLevelExp = 0
  costGold = 0
  isReadyForLevelUp = false
  isMaxLevel = false
  isNextStarLevel = false
  isStarProgress = false
}

let allUnitsCfg = Computed(function() {
  let unitLevels = campConfigs.value?.unitLevels ?? {}
  return (campConfigs.value?.allUnits ?? {}).map(@(u) u.__merge({
    levels = unitLevels?[u?.levelPreset ?? "0"] ?? []
  }))
})

let myUnits = Computed(function() {
  let cfg = allUnitsCfg.value
  let { upgradeUnitBonus = {} } = campConfigs.value?.gameProfile
  return units.value.map(@(u)
    (cfg?[u.name] ?? {}).__merge(u, (u?.isUpgraded ?? false) ? upgradeUnitBonus : {}))
})

let curUnitInProgressExt = Watched(curUnitInProgress.value)
curUnitInProgress.subscribe(@(v) v != null ? curUnitInProgressExt(v)
  : deferOnce(@() curUnitInProgressExt(curUnitInProgress.value)))

let curUnit = Computed(function() {
  let my = myUnits.get()
  local res = my?[curUnitInProgressExt.value]
    ?? my.findvalue(@(u) u?.isCurrent)
  let slots = curCampaignSlotUnits.get()
  if (slots != null) {
    if (slots.findvalue(@(n) n == res?.name))
      return res
    res = my?[slots.findvalue(@(n) n in my)]
  }
  return res ?? my.findvalue(@(_) true)
})
let curUnitName = Computed(@() curUnit.value?.name)
let battleUnitsMaxMRank = Computed(@() curCampaignSlotUnits.get() == null ? (curUnit.value?.mRank ?? 0)
  : curCampaignSlotUnits.get().reduce(@(res, name) max(res, campConfigs.get()?.allUnits[name].mRank ?? 0), 0))

let playerLevelInfo = Computed(function() {
  let res = defaultProfileLevelInfo.__merge(levelInfo.value)
  let { playerLevels = null, playerLevelsInfo = null } = campConfigs.value
  let { maxBaseLevel = null, maxLevel = 0 } = playerLevelsInfo
  let levelCfg = playerLevels?[min(res.level, maxBaseLevel ?? res.level)]
  if (levelCfg == null || maxLevel <= res.level)
    res.isMaxLevel = true
  else {
    res.__update(levelCfg)
    if (res.exp >= res.nextLevelExp) {
      res.isReadyForLevelUp = true
      if (maxBaseLevel != null && res.level >= maxBaseLevel)
        res.isNextStarLevel = true
    }
    if (res.starLevel == 0)
      foreach(h in res?.starLevelHistory ?? [])
        if (h.baseLevel == res.level)
          res.historyStarLevel = h.starLevel + 1 //player have reseted exp in such case, so show one more star for him
  }
  return res
})

return {
  allUnitsCfg
  myUnits
  curUnit
  battleUnitsMaxMRank
  curUnitName
  playerLevelInfo
}