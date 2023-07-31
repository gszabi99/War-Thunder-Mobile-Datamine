from "%globalsDarg/darg_library.nut" import *
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { buy_unit_mod, enable_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")

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
    if (mod.group not in result)
      result[mod.group] <- {}
    result[mod.group][modName] <- mod
  }
  return result
})

let mods = Computed(@() modsPresets.value?[unitModPreset.value] ?? {})
let modsCategories = Computed(@() modsByCategory.value.keys().sort(@(a, b) a <=> b) ?? [])
let modsSorted = Computed(@() modsByCategory.value?[curCategoryId.value]?.values()
  .sort(@(a, b) a.reqLevel <=> b.reqLevel || a.name <=> b.name) ?? [])
let curMod = Computed(@() mods.value?[curModId.value])
let curModIndex = keepref(Computed(@() modsSorted.value.findindex(@(v) v?.name == curModId.value)))
let isCurModPurchased = Computed(@() unitMods.value?[curModId.value] != null)
let isCurModEnabled = Computed(@() unitMods.value?[curModId.value] == true)
let isCurModLocked = Computed(@() (curMod.value?.reqLevel ?? 0) > (unit.value?.level ?? 0))

let function openUnitModsWnd() {
  curCategoryId(modsCategories.value?[0])
  isUnitModsOpen(true)
}

let getModCurrency = @(mod) (mod?.costWp ?? 0) > 0 ? "wp" : "gold"
let getModCost = @(mod) (mod?.costWp ?? 0) > 0 ? mod?.costWp : mod?.costGold

curCategoryId.subscribe(@(_)
  curModId(modsSorted.value.findvalue(@(v) unitMods.value?[v.name] == true)?.name))

let enableCurUnitMod = @() enable_unit_mod(unitName.value, curModId.value, true)
let disableCurUnitMod = @() enable_unit_mod(unitName.value, curModId.value, false)

let buyCurUnitMod = @() buy_unit_mod(unitName.value, curModId.value, getModCurrency(curMod.value), getModCost(curMod.value))

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
  modsSorted
  modsCategories
  unit
  unitMods

  buyCurUnitMod
  enableCurUnitMod
  disableCurUnitMod

  getModCurrency
  getModCost
}
