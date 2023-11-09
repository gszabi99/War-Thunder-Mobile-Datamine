let { deferOnce } = require("dagor.workcycle")
let { Computed, Watched } = require("frp")
let { units, levelInfo, campConfigs } = require("campaign.nut")
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

let curUnit = Computed(@() myUnits.value?[curUnitInProgressExt.value]
  ?? myUnits.value.findvalue(@(u) u?.isCurrent)
  ?? myUnits.value.findvalue(@(_) true))
let curUnitMRank = Computed(@() curUnit.value?.mRank ?? 0)
let curUnitName = Computed(@() curUnit.value?.name)

let playerLevelInfo = Computed(function() {
  let res = defaultProfileLevelInfo.__merge(levelInfo.value)
  let { playerLevels = null, playerLevelsInfo = null } = campConfigs.value
  let levelCfg = playerLevels?[res.level]
  if (levelCfg == null)
    res.isMaxLevel = true
  else {
    res.__update(levelCfg)
    if (res.exp >= res.nextLevelExp) {
      res.isReadyForLevelUp = true
      let { maxBaseLevel = null } = playerLevelsInfo
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

let allUnitsCfgFlat = Computed(function() {
  let cfg = allUnitsCfg.value
  let res = {}
  foreach (unit in cfg)
    foreach (pu in unit.platoonUnits)
      res[pu.name] <- unit.__merge(pu)
  res.__update(cfg)
  return res
})

return {
  allUnitsCfg
  allUnitsCfgFlat
  myUnits
  curUnit
  curUnitMRank
  curUnitName
  playerLevelInfo
}