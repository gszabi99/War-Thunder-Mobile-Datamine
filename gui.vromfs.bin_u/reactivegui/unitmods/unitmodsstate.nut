from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { enable_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { roundPrice } = require("%appGlobals/pServer/pServerMath.nut")

let SEEN_MODS = "seenMods"
let seenMods = mkWatched(persist, "SEEN_MODS", {})

let modsSort = @(a, b) a.reqLevel <=> b.reqLevel || a.name <=> b.name

let isUnitModsOpen = mkWatched(persist, "isUnitModsOpen", false)
let curCategoryId = mkWatched(persist, "curCategoryId", "")
let curModId = mkWatched(persist, "curModId", "")
let unit = Computed(@() myUnits.value?[hangarUnitName.value])
let unitName = Computed(@() unit.value?.name)
let unitMods = Computed(@() unit.value?.mods)
let unitModPreset = Computed(@() unit.value?.modPreset)

let modsPresets = Computed(function() {
  let { unitModPresets = [] } = campConfigs.value
  let result = {}
  foreach(presetName, preset in unitModPresets) {
    result[presetName] <- {}
    foreach(modName, mod in preset)
      result[presetName][modName] <- mod.__merge({ name = modName })
  }
  return result
})

let modsByCategory = Computed(function() {
  let result = {}
  foreach(modName, mod in modsPresets.value?[unitModPreset.value] ?? {}) {
    if (mod?.isHidden)
      continue
    if (mod.group not in result)
      result[mod.group] <- {}
    result[mod.group][modName] <- mod
  }
  return result
})

let mods = Computed(@() modsPresets.value?[unitModPreset.value] ?? {})
let modsCategories = Computed(@() modsByCategory.value.keys().sort(@(a, b) a <=> b) ?? [])
let modsSorted = Computed(@() modsByCategory.value?[curCategoryId.value]?.values().sort(modsSort) ?? [])
let curMod = Computed(@() mods.value?[curModId.value])
let curModIndex = keepref(Computed(@() modsSorted.value.findindex(@(v) v?.name == curModId.value)))
let isCurModPurchased = Computed(@() unitMods.value?[curModId.value] != null)
let isCurModEnabled = Computed(@() unitMods.value?[curModId.value] == true)
let isCurModLocked = Computed(@() (curMod.value?.reqLevel ?? 0) > (unit.value?.level ?? 0))

let unseenModsByCategory = Computed(function() {
  let res = {}
  foreach (cat, modsInCat in modsByCategory.value) {
    res[cat] <- {}
    foreach (mod in modsInCat)
      if (mod.name not in seenMods.value?[unitName.value]
          && (mod.reqLevel ?? 0) <= (unit.value?.level ?? 0)
          && mod.name not in unitMods.value)
        res[cat][mod.name] <- true
  }
  return res.filter(@(v) v.len() > 0)
})

let function openUnitModsWnd() {
  curCategoryId(modsCategories.value?[0])
  isUnitModsOpen(true)
}

let curUnitAllModsCost = Computed(function() {
  let { costWp = 0, modCostPart = 0.0, campaign = "", rank = 0 } = unit.value
  if (modCostPart <= 0)
    return 0
  let cost = costWp > 0 ? costWp : (serverConfigs.value?.unitsAvgCostWp[campaign][rank] ?? 0)
  return modCostPart.tofloat() * cost
})

//costWp - compatibility with PServer at 24.07.2023 (0.0.11.X)
let getModCurrency = @(mod) (mod?.costWp ?? 0) > 0 || (mod?.costWpWeight ?? 0) > 0 ? "wp" : "gold"
let function getModCost(mod, allModsCost) {
  let { costWp = 0, costWpWeight = 0, costGold = 0 } = mod
  if (costWp > 0) //compatibility with PServer at 24.07.2023 (0.0.11.X)
    return costWp
  if (costWpWeight <= 0) //compatibility with PServer at 24.07.2023 (0.0.11.X)
    return costGold
  return roundPrice(costWpWeight.tofloat() * allModsCost)
}

let mkCurUnitModCostComp = @(mod) Computed(@() getModCost(mod, curUnitAllModsCost.value))

curCategoryId.subscribe(@(_)
  curModId(modsSorted.value.findvalue(@(v) unitMods.value?[v.name] == true)?.name))

let enableCurUnitMod = @() enable_unit_mod(unitName.value, curModId.value, true)
let disableCurUnitMod = @() enable_unit_mod(unitName.value, curModId.value, false)

let function setCurUnitSeenMods(ids) {
  if (!unitName.value)
    return
  seenMods.mutate(function(v) {
    foreach (id in ids) {
      if (unitName.value not in v)
        v[unitName.value] <- {}
      v[unitName.value][id] <- true
    }
  })
  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_MODS)
  let blk = sBlk.addBlock(unitName.value)
  foreach (id, isSeen in seenMods.value?[unitName.value] ?? {})
    if (isSeen)
      blk[id] = true
  send("saveProfile", {})
}


let function loadSeenMods() {
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SEEN_MODS]
  if (!isDataBlock(htBlk)) {
    seenMods({})
    return
  }
  let res = {}
  foreach (unitId, modsIds in htBlk) {
    let unitSeenMods = {}
    eachParam(modsIds, @(isSeen, id) unitSeenMods[id] <- isSeen)
    if (unitSeenMods.len() > 0)
      res[unitId] <- unitSeenMods
  }
  seenMods(res)
}

if (seenMods.value.len() == 0)
  loadSeenMods()

let setCurUnitSeenModsCurrent = @() curCategoryId.value not in unseenModsByCategory.value ? null
  : setCurUnitSeenMods(unseenModsByCategory.value?[curCategoryId.value].keys())

let function onTabChange(id) {
  setCurUnitSeenModsCurrent()
  curCategoryId(id)
}

register_command(function() {
  seenMods({})
  get_local_custom_settings_blk().removeBlock(SEEN_MODS)
  send("saveProfile", {})
}, "debug.reset_seen_mods")

return {
  openUnitModsWnd
  closeUnitModsWnd = @() isUnitModsOpen(false)
  isUnitModsOpen
  curCategoryId
  curMod
  curModId
  curModIndex
  isCurModPurchased
  isCurModEnabled
  isCurModLocked

  mods
  modsSort
  modsSorted
  modsCategories
  modsByCategory
  unit
  unitMods
  curUnitAllModsCost

  enableCurUnitMod
  disableCurUnitMod

  getModCurrency
  getModCost
  mkCurUnitModCostComp

  setCurUnitSeenModsCurrent
  unseenModsByCategory
  onTabChange
}
