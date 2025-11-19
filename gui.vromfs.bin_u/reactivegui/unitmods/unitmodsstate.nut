from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { hangarUnitName, hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { enable_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { roundPrice } = require("%appGlobals/pServer/pServerMath.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { BULLETS_PRIM_SLOTS } = require("%rGui/bullets/bulletsConst.nut")
let { iconsCfg } = require("%rGui/unitMods/unitModsConst.nut")
let { unseenCampUnitMods, markUnitModsSeen } = require("%rGui/unitMods/unseenMods.nut")
let { getUnseenUnitBulletsNonUpdatable, markShellsSeen } = require("%rGui/unitMods/unseenBullets.nut")
let { baseUnit } = require("%rGui/unitDetails/unitDetailsState.nut")


let slotModKey = @(idx) $"unit_mods_slot_mod_{idx}"

let isUnitModsOpen = mkWatched(persist, "isUnitModsOpen", false)
let isUnitModAttached = mkWatched(persist, "isUnitModAttached", false)
let curModCategoryId = mkWatched(persist, "curModCategoryId", null)
let curModId = mkWatched(persist, "curModId", null)
let curBullet = mkWatched(persist, "curBullet", null)
let curBulletCategoryId = mkWatched(persist, "curBulletCategoryId", null)

let isOwn = Computed(@() hangarUnitName.get() in campMyUnits.get())
let unit = Computed(@() !isUnitModsOpen.get() ? null
  : (baseUnit.get() ?? campMyUnits.get()?[hangarUnit.get()?.name] ?? campUnitsCfg.get()?[hangarUnit.get()?.name]))
let unitName = Computed(@() unit.get()?.name)
let unitMods = Computed(@() unit.get()?.mods)

let modsPresets = Computed(function() {
  let { unitModPresets = {} } = campConfigs.get()
  let result = {}
  foreach(presetName, preset in unitModPresets) {
    result[presetName] <- {}
    foreach(modName, mod in preset)
      result[presetName][modName] <- mod.__merge({ name = modName })
  }
  return result
})

let mkMods = @(u) Computed(@() modsPresets.get()?[u.get()?.modPreset] ?? {})
let mods = mkMods(unit)
let modsByCategory = Computed(function() {
  let result = {}
  foreach(modName, mod in mods.get()) {
    if (mod?.isHidden)
      continue
    if (mod.group not in result)
      result[mod.group] <- {}
    result[mod.group][modName] <- mod
  }
  return result
})

let modsSort = @(a, b) a.reqLevel <=> b.reqLevel || a.name <=> b.name

let modsCategories = Computed(@() modsByCategory.get().keys().sort(@(a, b) a <=> b) ?? [])
let modsSorted = Computed(@() modsByCategory.get()?[curModCategoryId.get()]?.values().sort(modsSort) ?? [])
let curMod = Computed(@() mods.get()?[curModId.get()])
let isCurModPurchased = Computed(@() unitMods.get()?[curModId.get()] != null)
let isCurModEnabled = Computed(@() unitMods.get()?[curModId.get()] == true)
let isCurModLocked = Computed(@() (curMod.get()?.reqLevel ?? 0) > (unit.get()?.level ?? 0))

let iconCfg = Computed(@() iconsCfg?[unit.get()?.unitType] ?? iconsCfg.tank)

let unseenModsByCategory = Computed(function() {
  let res = {}
  let unseen = unseenCampUnitMods.get()?[unitName.get()]
  if (unseen == null || !isUnitModsOpen.get())
    return res
  foreach (cat, modsInCat in modsByCategory.get())
    foreach (mod in modsInCat)
      if (mod.name in unseen)
        getSubTable(res, cat)[mod.name] <- true
  return res
})

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
  return costWpWeight <= 0 ? costGold <= (allBalance?[GOLD] ?? 0)
    : roundPrice(costWpWeight.tofloat() * allModsCost) <= (allBalance?[WP] ?? 0)
}

let mkCurUnitModCostComp = @(mod) Computed(@() getModCost(mod, curUnitAllModsCost.get()))

let enableCurUnitMod = @() enable_unit_mod(unitName.get(), curModId.get(), true)
let disableCurUnitMod = @() enable_unit_mod(unitName.get(), curModId.get(), false)

function changeModTabWithUnseenTrigger(id) {
  if (unitName.get() != null && curModCategoryId.get() in unseenModsByCategory.get())
    markUnitModsSeen(unitName.get(), unseenModsByCategory.get()?[curModCategoryId.get()].keys())
  curModCategoryId.set(id)
}

function changeBulletTabWithUnseenTrigger(id) {
  let prevId = curBulletCategoryId.get()
  if (id == null || (id < BULLETS_PRIM_SLOTS) != (prevId < BULLETS_PRIM_SLOTS)) {
    let uName = unitName.get()
    let { primary, secondary } = getUnseenUnitBulletsNonUpdatable(uName)
    let unseenBullets = prevId < BULLETS_PRIM_SLOTS ? primary : secondary
    if (unseenBullets.len() > 0)
      markShellsSeen(uName, unseenBullets.keys())
  }
  curBulletCategoryId.set(id)
}

let onModTabChange = @(id) changeModTabWithUnseenTrigger(id)

function openUnitModsWnd() {
  isUnitModsOpen.set(true)
}

function closeUnitModsWnd() {
  changeModTabWithUnseenTrigger(null)
  changeBulletTabWithUnseenTrigger(null)
  isUnitModsOpen.set(false)
}

curModCategoryId.subscribe(function(v) {
  if (v == null)
    return
  curBullet.set(null)
  changeBulletTabWithUnseenTrigger(null)
  curModId.set(modsSorted.get().findvalue(@(m) unitMods.get()?[m.name] == true)?.name)
})

isUnitModsOpen.subscribe(@(v) sendNewbieBqEvent(v ? "openUnitModificationsWnd" : "closeUnitModificationsWnd"))

return {
  openUnitModsWnd
  closeUnitModsWnd
  isUnitModsOpen
  isUnitModAttached
  slotModKey

  curModCategoryId
  curMod
  curModId
  curBulletCategoryId
  curBullet
  isCurModPurchased
  isCurModEnabled
  isCurModLocked

  modsPresets
  mods
  modsSort
  modsSorted
  mkMods
  modsCategories
  modsByCategory
  unit
  unitName
  unitMods
  isOwn
  curUnitAllModsCost

  enableCurUnitMod
  disableCurUnitMod

  mkUnitAllModsCost
  getModCurrency
  getModCost
  mkCurUnitModCostComp

  changeBulletTabWithUnseenTrigger
  changeModTabWithUnseenTrigger
  unseenModsByCategory
  onModTabChange
  hasEnoughCurrencies

  iconCfg
}
