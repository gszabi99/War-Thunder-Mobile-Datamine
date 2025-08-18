from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { enable_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { roundPrice } = require("%appGlobals/pServer/pServerMath.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")

let SEEN_MODS = "seenMods"
let seenMods = mkWatched(persist, "SEEN_MODS", {})

let modsSort = @(a, b) a.reqLevel <=> b.reqLevel || a.name <=> b.name

let isUnitModsOpen = mkWatched(persist, "isUnitModsOpen", false)
let curCategoryId = mkWatched(persist, "curCategoryId", "")
let curModId = mkWatched(persist, "curModId", "")
let unit = Computed(@() campMyUnits.get()?[hangarUnitName.get()])
let unitName = Computed(@() unit.get()?.name)
let unitMods = Computed(@() unit.get()?.mods)
let unitModPreset = Computed(@() unit.get()?.modPreset)

isUnitModsOpen.subscribe(@(v) sendNewbieBqEvent(v ? "openUnitModificationsWnd" : "closeUnitModificationsWnd"))

let modsPresets = Computed(function() {
  let { unitModPresets = [] } = campConfigs.get()
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
  foreach(modName, mod in modsPresets.get()?[unitModPreset.get()] ?? {}) {
    if (mod?.isHidden)
      continue
    if (mod.group not in result)
      result[mod.group] <- {}
    result[mod.group][modName] <- mod
  }
  return result
})

let mods = Computed(@() modsPresets.get()?[unitModPreset.get()] ?? {})
let modsCategories = Computed(@() modsByCategory.get().keys().sort(@(a, b) a <=> b) ?? [])
let modsSorted = Computed(@() modsByCategory.get()?[curCategoryId.get()]?.values().sort(modsSort) ?? [])
let curMod = Computed(@() mods.get()?[curModId.get()])
let curModIndex = keepref(Computed(@() modsSorted.get().findindex(@(v) v?.name == curModId.get())))
let isCurModPurchased = Computed(@() unitMods.get()?[curModId.get()] != null)
let isCurModEnabled = Computed(@() unitMods.get()?[curModId.get()] == true)
let isCurModLocked = Computed(@() (curMod.get()?.reqLevel ?? 0) > (unit.get()?.level ?? 0))

let unseenModsByCategory = Computed(function() {
  let res = {}
  foreach (cat, modsInCat in modsByCategory.get()) {
    res[cat] <- {}
    foreach (mod in modsInCat)
      if (mod.name not in seenMods.get()?[unitName.get()]
          && (mod.reqLevel ?? 0) <= (unit.get()?.level ?? 0)
          && mod.name not in unitMods.get())
        res[cat][mod.name] <- true
  }
  return res.filter(@(v) v.len() > 0)
})

function openUnitModsWnd() {
  curCategoryId.set(modsCategories.get()?[0])
  isUnitModsOpen.set(true)
}

let mkUnitAllModsCost = @(unitW) Computed(function() {
  let { costWp = 0, modCostPart = 0.0, campaign = "", rank = 0 } = unitW.get()
  if (modCostPart <= 0)
    return 0
  let cost = costWp > 0 ? costWp : (serverConfigs.get()?.unitsAvgCostWp[campaign][rank] ?? 0)
  return modCostPart.tofloat() * cost
})

let curUnitAllModsCost = mkUnitAllModsCost(unit)

let getModCurrency = @(mod) (mod?.costWpWeight ?? 0) > 0 ? "wp" : "gold"
function getModCost(mod, allModsCost) {
  let { costWpWeight = 0, costGold = 0 } = mod
  if (costWpWeight <= 0)
    return costGold
  return roundPrice(costWpWeight.tofloat() * allModsCost)
}

function hasEnoughCurrencies(mod, allModsCost, allBalance) {
  let { costWpWeight = 0, costGold = 0 } = mod
  if (costWpWeight <= 0)
    return costGold <= (allBalance?[GOLD] ?? 0)
  return costWpWeight.tofloat() * allModsCost <= (allBalance?[WP] ?? 0)
}

let mkCurUnitModCostComp = @(mod) Computed(@() getModCost(mod, curUnitAllModsCost.value))

curCategoryId.subscribe(@(_)
  curModId.set(modsSorted.get().findvalue(@(v) unitMods.get()?[v.name] == true)?.name))

let enableCurUnitMod = @() enable_unit_mod(unitName.get(), curModId.get(), true)
let disableCurUnitMod = @() enable_unit_mod(unitName.get(), curModId.get(), false)

function setCurUnitSeenMods(ids) {
  if (!unitName.get())
    return
  seenMods.mutate(function(v) {
    foreach (id in ids) {
      if (unitName.get() not in v)
        v[unitName.get()] <- {}
      v[unitName.get()][id] <- true
    }
  })
  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_MODS)
  let blk = sBlk.addBlock(unitName.get())
  foreach (id, isSeen in seenMods.get()?[unitName.get()] ?? {})
    if (isSeen)
      blk[id] = true
  eventbus_send("saveProfile", {})
}


function loadSeenMods() {
  if (!isSettingsAvailable.get())
    return seenMods.set({})
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SEEN_MODS]
  if (!isDataBlock(htBlk)) {
    seenMods.set({})
    return
  }
  let res = {}
  foreach (unitId, modsIds in htBlk) {
    let unitSeenMods = {}
    eachParam(modsIds, @(isSeen, id) unitSeenMods[id] <- isSeen)
    if (unitSeenMods.len() > 0)
      res[unitId] <- unitSeenMods
  }
  seenMods.set(res)
}

if (seenMods.get().len() == 0)
  loadSeenMods()

isSettingsAvailable.subscribe(@(_) loadSeenMods())

let setCurUnitSeenModsCurrent = @() curCategoryId.get() not in unseenModsByCategory.get() ? null
  : setCurUnitSeenMods(unseenModsByCategory.get()?[curCategoryId.get()].keys())

function onTabChange(id) {
  setCurUnitSeenModsCurrent()
  curCategoryId.set(id)
}

register_command(function() {
  seenMods.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_MODS)
  eventbus_send("saveProfile", {})
}, "debug.reset_seen_mods")

return {
  openUnitModsWnd
  closeUnitModsWnd = @() isUnitModsOpen.set(false)
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

  mkUnitAllModsCost
  getModCurrency
  getModCost
  mkCurUnitModCostComp

  setCurUnitSeenModsCurrent
  unseenModsByCategory
  onTabChange
  hasEnoughCurrencies
}
