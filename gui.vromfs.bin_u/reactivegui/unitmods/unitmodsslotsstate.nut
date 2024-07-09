from "%globalsDarg/darg_library.nut" import *
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { mkWeaponPreset, getWeaponPreset } = require("%rGui/unit/unitSettings.nut")
let { mkUnitAllModsCost, getModCurrency, getModCost } = require("unitModsState.nut")


let openedUnitId = mkWatched(persist, "openedUnitId", null)
let unitModSlotsOpenCount = Watched(openedUnitId.get() == null ? 0 : 1)
let curSlotIdx = mkWatched(persist, "curSlotIdx", 0)
let curWeaponIdx = mkWatched(persist, "curWeaponIdx", 0)

let curUnit = Computed(@() myUnits.get()?[openedUnitId.get()])
let isHangarUnitHasWeaponSlots = Computed(@() isLoggedIn.get() && loadUnitWeaponSlots(hangarUnitName.get()).len() > 0)

openedUnitId.subscribe(function(v) {
  unitModSlotsOpenCount.set(v == null ? 0 : unitModSlotsOpenCount.get() + 1)
  curSlotIdx.set(0)
})

let weaponSlots = Computed(@() openedUnitId.get() == null ? [] : loadUnitWeaponSlots(openedUnitId.get()))
let curSlot = Computed(@() weaponSlots.get()?[curSlotIdx.get()])
let curWeapons = Computed(@() curSlot.get()?.wPresets ?? {})

let curWeaponsOrdered = Computed(function() {
  if (curSlot.get() == null)
    return []
  let { wPresets, wPresetsOrder } = curSlot.get()
  return wPresetsOrder.map(@(id) wPresets[id])
})

let curWeapon = Computed(@() curWeaponsOrdered.get()?[curWeaponIdx.get()])

let curMods = Computed(@() campConfigs.get()?.unitModPresets[curUnit.get()?.modPreset])
let curUnitAllModsCost = mkUnitAllModsCost(curUnit)

let { weaponPreset, setWeaponPreset } = mkWeaponPreset(openedUnitId)

let function getEquippedWeapon(wPreset, slotIdx, weaponsList, unitMods = null) {
  let id = wPreset?[slotIdx]
  local res = weaponsList?[id]
  let { reqModification = "" } = res
  if (reqModification != "" && reqModification not in unitMods)
    res = null
  return res ?? weaponsList.findvalue(@(w) w.isDefault)
}

let equippedWeaponId = Computed(@()
  getEquippedWeapon(weaponPreset.get(), curSlotIdx.get(), curWeapons.get(), curUnit.get()?.mods)?.name)

curSlotIdx.subscribe(@(_) curWeaponIdx.set(curWeaponsOrdered.get().findindex(@(w) w.name == equippedWeaponId.get()) ?? 0))

function equipWeapon(slotIdx, weaponId) {
  let preset = clone weaponPreset.get()
  if (slotIdx >= preset.len())
    preset.resize(slotIdx + 1, "")
  preset[slotIdx] = weaponId
  setWeaponPreset(preset)
}

let equipCurWeapon = @() equipWeapon(curSlotIdx.get(), curWeapon.get()?.name ?? "")
let unequipCurWeapon = @() equipWeapon(curSlotIdx.get(), "")

function mkWeaponStates(weapon, unitMods, unit) {
  let modName = Computed(@() weapon.get()?.reqModification ?? "")
  let mod = Computed(@() unitMods.get()?[modName.get()])
  let reqLevel = Computed(@() mod.get()?.reqLevel ?? 0)
  let isLocked = Computed(@() reqLevel.get() > (unit.get()?.level ?? 0)
    || (modName.get() != "" && mod.get() == null))
  let isPurchased = Computed(@() modName.get() == "" || unit.get()?.mods[modName.get()] != null)
  return { modName, mod, reqLevel, isLocked, isPurchased }
}

let { curWeaponModName, curWeaponMod, curWeaponReqLevel, curWeaponIsLocked, curWeaponIsPurchased
} = mkWeaponStates(curWeapon, curMods, curUnit)
  .reduce(@(res, v, k) res.$rawset($"curWeapon{k.slice(0, 1).toupper()}{k.slice(1)}", v), {})

function getUnitSlotsPresetNonUpdatable(unitName, mods) {
  let wPreset = getWeaponPreset(unitName)
  let slots = loadUnitWeaponSlots(unitName)
  let res = {}
  foreach(idx, s in slots) {
    let weapon = getEquippedWeapon(wPreset, idx, s?.wPresets ?? {}, mods)
    if (weapon != null)
      res[idx] <- weapon.name
  }
  return res
}

return {
  openUnitModsSlotsWnd = @() openedUnitId.set(hangarUnitName.get())
  closeUnitModsSlotsWnd = @() openedUnitId.set(null)
  unitModSlotsOpenCount
  isHangarUnitHasWeaponSlots

  curUnit
  weaponSlots
  curSlotIdx
  curSlot
  curWeapons
  curWeaponsOrdered
  curWeaponIdx
  curWeapon
  curMods
  curWeaponModName
  curWeaponMod
  curWeaponReqLevel
  curWeaponIsLocked
  curWeaponIsPurchased
  weaponPreset
  equippedWeaponId
  getEquippedWeapon

  curUnitAllModsCost
  getModCurrency
  getModCost
  mkWeaponStates
  equipCurWeapon
  unequipCurWeapon
  getUnitSlotsPresetNonUpdatable
}
