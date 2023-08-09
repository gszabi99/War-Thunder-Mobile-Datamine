
let { Computed } = require("frp")
let { units, levelInfo, campConfigs } = require("campaign.nut")
let { curUnitInProgress } = require("pServerApi.nut")

let defaultProfileLevelInfo = {
  exp = 0,
  level = 1,
  seenLevel = 1
  nextLevelExp = 0
  costGold = 0
  minUnitRank = 100000
  maxUnitRank = 100000
  isReadyForLevelUp = false
  isMaxLevel = false
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

let curUnit = Computed(@() myUnits.value?[curUnitInProgress.value]
  ?? myUnits.value.findvalue(@(u) u?.isCurrent)
  ?? myUnits.value.findvalue(@(_) true))
let curUnitMRank = Computed(@() curUnit.value?.mRank ?? 0)

let playerLevelInfo = Computed(function() {
  let res = defaultProfileLevelInfo.__merge(levelInfo.value)
  let levelCfg = campConfigs.value?.playerLevels[res.level]
  if (levelCfg == null)
    res.isMaxLevel = true
  else {
    res.__update(levelCfg)
    if (res.exp >= res.nextLevelExp)
      res.isReadyForLevelUp = true
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
  playerLevelInfo
}