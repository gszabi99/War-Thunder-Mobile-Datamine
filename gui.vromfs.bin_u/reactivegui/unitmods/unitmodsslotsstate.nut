from "%globalsDarg/darg_library.nut" import *
let { round_by_value, fabs } = require("%sqstd/math.nut")
let { loadUnitWeaponSlots, loadUnitSlotsParams } = require("%rGui/weaponry/loadUnitBullets.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { mkWeaponPreset, getWeaponPreset, mkChosenBelts, getChosenBelts } = require("%rGui/unit/unitSettings.nut")
let { mkUnitAllModsCost, getModCurrency, getModCost } = require("unitModsState.nut")
let { getEquippedWeapon, getEqippedWithoutOverload } = require("equippedSecondaryWeapons.nut")


let DEFAULT_SLOT_IDX = 1

let openedUnitId = mkWatched(persist, "openedUnitId", null)
let unitModSlotsOpenCount = Watched(openedUnitId.get() == null ? 0 : 1)
let curSlotIdx = mkWatched(persist, "curSlotIdx", DEFAULT_SLOT_IDX)
let curBeltsWeaponIdx = mkWatched(persist, "curBeltsWeaponIdx", -1)
let curWeaponIdx = mkWatched(persist, "curWeaponIdx", 0)
let curBeltIdx = mkWatched(persist, "curBeltIdx", 0)

let curUnit = Computed(@() myUnits.get()?[openedUnitId.get()] || allUnitsCfg.get()?[openedUnitId.get()])
let isOwn = Computed(@() openedUnitId.get() in myUnits.get())
let isHangarUnitHasWeaponSlots = Computed(@() isLoggedIn.get() && loadUnitWeaponSlots(hangarUnitName.get()).len() > 0)

openedUnitId.subscribe(function(v) {
  unitModSlotsOpenCount.set(v == null ? 0 : unitModSlotsOpenCount.get() + 1)
  curSlotIdx.set(DEFAULT_SLOT_IDX)
})

curBeltsWeaponIdx.subscribe(@(v) v < 0 ? null : curSlotIdx.set(-1))
curSlotIdx.subscribe(@(v) v < 0 ? null : curBeltsWeaponIdx.set(-1))

let weaponSlots = Computed(@() openedUnitId.get() == null ? [] : loadUnitWeaponSlots(openedUnitId.get()))
let curSlot = Computed(@() weaponSlots.get()?[curSlotIdx.get()])
let curWeapons = Computed(@() curSlot.get()?.wPresets ?? {})

function isBeltWeapon(weapon) {
  let { trigger, turrets } = weapon
  return turrets > 0 || trigger == "machine gun" || trigger == "cannon" || trigger == "additional gun"
}

let beltWeapons = Computed(function() {
  let res = []
  let added = {}
  let skipped = {}
  foreach(slot in weaponSlots.get())
    foreach(presetId in slot.wPresetsOrder)
      foreach(weapon in slot.wPresets[presetId].weapons) {
        let { weaponId } = weapon
        if (weaponId in skipped)
          continue
        if (weaponId in added) {
          added[weaponId].count++
          continue
        }
        if (!isBeltWeapon(weapon)) {
          skipped[weaponId] <- true
          continue
        }
        let caliber = weapon.bulletSets.findvalue(@(_) true)?.caliber ?? 0
        let w = weapon.__merge({ count = 1, caliber })
        res.append(w)
        added[weaponId] <- w
      }
  return res.sort(@(a, b) (a.turrets > 0) <=> (b.turrets > 0)
    || b.caliber <=> a.caliber)
})

let curWeaponsOrdered = Computed(function() {
  if (curSlot.get() == null)
    return []
  let { wPresets, wPresetsOrder } = curSlot.get()
  return wPresetsOrder.map(@(id) wPresets[id])
})

let curWeapon = Computed(@() curWeaponsOrdered.get()?[curWeaponIdx.get()])
let curBeltWeapon = Computed(@() beltWeapons.get()?[curBeltsWeaponIdx.get()])

function mkWeaponBelts(unitName, weapon) {
  if (weapon == null || unitName == null)
    return {}
  let { bulletSets, weaponId } = weapon
  let bulletsTags = getUnitTagsCfg(unitName)?.bullets[weaponId] ?? {}
  return bulletSets
    .filter(@(_, id) id == "" || id in bulletsTags)
    .map(@(bSet) bSet.__merge({ reqModification = bulletsTags?[bSet.id].reqModification ?? "" }))
}

let curWeaponBelts = Computed(@() mkWeaponBelts(openedUnitId.get(), curBeltWeapon.get()))

let curWeaponBeltsOrdered = Computed(function() {
  if (curWeaponBelts.get().len() == 0)
    return []
  let bulletsOrder = getUnitTagsCfg(openedUnitId.get())?.bulletsOrder[curBeltWeapon.get()?.weaponId] ?? [""]
  return bulletsOrder.map(@(id) curWeaponBelts.get()?[id])
    .filter(@(v) v != null)
})

let curBelt = Computed(@() curWeaponBeltsOrdered.get()?[curBeltIdx.get()])

let curMods = Computed(@() campConfigs.get()?.unitModPresets[curUnit.get()?.modPreset])
let curUnitAllModsCost = mkUnitAllModsCost(curUnit)

let { weaponPreset, setWeaponPreset } = mkWeaponPreset(openedUnitId)


let equippedWeaponsBySlots = Computed(@()
  weaponSlots.get().map(@(slot, idx) getEquippedWeapon(weaponPreset.get(), idx, slot.wPresets, curUnit.get()?.mods)))
let equippedWeaponId = Computed(@() equippedWeaponsBySlots.get()?[curSlotIdx.get()].name)

let equippedWeaponIdCount = Computed(@() equippedWeaponsBySlots.get()
  .reduce(function(res, weapon) {
    if (weapon != null)
      foreach(w in weapon.weapons)
        res[w.weaponId] <- (res?[w.weaponId] ?? 0) + 1
    return res
  },
  {}))

let massText = @(mass) "".concat(round_by_value(mass, 0.1), loc("measureUnits/kg"))

function appendOverloadMsg(res, locKey, mass, maxMass) {
  let overload = mass - maxMass
  if (overload <= 0)
    return
  res.append(loc(locKey, {
    overload = massText(overload)
    weight = massText(mass)
    maxWeight = massText(maxMass)
  }))
}

function calcOverloadInfo(unitName, eqWeaponsBySlots) {
  let { maxDisbalance = 0, maxloadMass = 0, maxloadMassLeftConsoles = 0, maxloadMassRightConsoles = 0,
    notUseForDisbalance = {}
  } = loadUnitSlotsParams(unitName)
  local massInfo = ""
  let overloads = []
  if (maxDisbalance <= 0 && maxloadMass <= 0 && maxloadMassLeftConsoles <= 0 && maxloadMassRightConsoles <= 0)
    return { massInfo, overloads }

  local massTotal = 0.0
  local massLeft = 0.0
  local massRight = 0.0
  let centerIdx = eqWeaponsBySlots.len() / 2
  foreach(index, preset in eqWeaponsBySlots) {
    let { mass = 0 } = preset
    if (mass <= 0)
      continue
    massTotal += mass
    if (notUseForDisbalance?[index] ?? (index == 0))
      continue
    if (index <= centerIdx)
      massLeft += mass
    else
      massRight += mass
  }
  if (maxloadMass > 0)
    massInfo = "".concat(loc("stats/mass"), colon,
      round_by_value(massTotal, 0.1), loc("ui/slash"),
      round_by_value(maxloadMass, 0.1), loc("measureUnits/kg"))

  appendOverloadMsg(overloads, "weapons/pylonsWeightSummaryOverload", massTotal, maxloadMass)
  appendOverloadMsg(overloads, "weapons/pylonsWeightLeftOverload", massLeft, maxloadMassLeftConsoles)
  appendOverloadMsg(overloads, "weapons/pylonsWeightRightOverload", massRight, maxloadMassRightConsoles)

  let disbalance = fabs(massLeft - massRight)
  if (disbalance > maxDisbalance)
    overloads.append(loc("weapons/pylonsWeightDisbalance", {
      side = loc(massLeft > massRight ? "side/left" : "side/right")
      disbalance = massText(disbalance)
      maxDisbalance = massText(maxDisbalance)
    }))

  return { massInfo, overloads }
}

let overloadInfo = Computed(@() openedUnitId.get() == null ? null
  : calcOverloadInfo(openedUnitId.get(), equippedWeaponsBySlots.get()))

function fixCurPresetOverload() {
  if (openedUnitId.get() == null)
    return
  let preset = getEqippedWithoutOverload(openedUnitId.get(), equippedWeaponsBySlots.get())
    .map(@(v) v?.name ?? "")
  setWeaponPreset(preset)
}

let { chosenBelts, setChosenBelts } = mkChosenBelts(openedUnitId)

let function getEquippedBelt(chosenBeltsV, weaponId, beltsList, unitMods = null) {
  let id = chosenBeltsV?[weaponId] ?? ""
  local res = beltsList?[id]
  let { reqModification = "" } = res
  if (reqModification != "" && reqModification not in unitMods)
    res = null
  return res ?? beltsList?[""] ?? beltsList.findvalue(@(_) true)
}

let equippedBeltId = Computed(@()
  getEquippedBelt(chosenBelts.get(), curBeltWeapon.get()?.weaponId, curWeaponBelts.get(), curUnit.get()?.mods)?.id)


curSlotIdx.subscribe(@(v) v < 0 ? null
  : curWeaponIdx.set(curWeaponsOrdered.get().findindex(@(w) w.name == equippedWeaponId.get()) ?? 0))
curBeltsWeaponIdx.subscribe(@(v) v < 0 ? null
  : curBeltIdx.set(curWeaponBeltsOrdered.get().findindex(@(b) b.id == equippedBeltId.get()) ?? 0))

function equipWeapon(slotIdx, weaponId) {
  let preset = clone weaponPreset.get()
  if (slotIdx >= preset.len())
    preset.resize(slotIdx + 1, "")
  preset[slotIdx] = weaponId
  setWeaponPreset(preset)
}

let equipCurWeapon = @() equipWeapon(curSlotIdx.get(), curWeapon.get()?.name ?? "")
let unequipCurWeapon = @() equipWeapon(curSlotIdx.get(), "")

function equipBelt(weaponId, beltId) {
  if (chosenBelts.get()?[weaponId] != beltId)
    setChosenBelts(chosenBelts.get().__merge({ [weaponId] = beltId }))
}

let equipCurBelt = @() curBeltWeapon.get() == null ? null
  : equipBelt(curBeltWeapon.get().weaponId, curBelt.get()?.id ?? "")

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
} = mkWeaponStates(Computed(@() curBelt.get() ?? curWeapon.get()), curMods, curUnit)
  .reduce(@(res, v, k) res.$rawset($"curWeapon{k.slice(0, 1).toupper()}{k.slice(1)}", v), {})

function getUnitSlotsPresetNonUpdatable(unitName, mods) {
  let wPreset = getWeaponPreset(unitName)
  let slots = loadUnitWeaponSlots(unitName)
  let weapons = getEqippedWithoutOverload(unitName,
    slots.map(@(s, idx) getEquippedWeapon(wPreset, idx, s?.wPresets ?? {}, mods)))

  let res = {}
  foreach(idx, weapon in weapons)
    if (weapon != null)
      res[idx] <- weapon.name
  return res
}

function getUnitBeltsNonUpdatable(unitName, mods) {
  let chosen = getChosenBelts(unitName)
  let slots = loadUnitWeaponSlots(unitName)
  let res = {}
  let processed = {}
  foreach(slot in slots)
    foreach(presetId in slot.wPresetsOrder)
      foreach(weapon in slot.wPresets[presetId].weapons) {
        let { weaponId } = weapon
        if (weaponId in processed)
          continue
        processed[weaponId] <- true
        if (!isBeltWeapon(weapon))
          continue
        res[weaponId] <- getEquippedBelt(chosen, weaponId, mkWeaponBelts(unitName, weapon), mods)?.id ?? ""
      }
  return res
}

return {
  openUnitModsSlotsWnd = @() openedUnitId.set(hangarUnitName.get())
  closeUnitModsSlotsWnd = @() openedUnitId.set(null)
  unitModSlotsOpenCount
  isHangarUnitHasWeaponSlots
  isOwn

  curUnit
  weaponSlots
  beltWeapons
  curSlotIdx
  curBeltsWeaponIdx
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
  equippedWeaponsBySlots
  equippedWeaponIdCount
  overloadInfo
  curBeltWeapon
  curWeaponBelts
  curWeaponBeltsOrdered
  curBeltIdx
  curBelt
  chosenBelts
  equippedBeltId
  getEquippedBelt
  mkWeaponBelts
  isBeltWeapon

  curUnitAllModsCost
  getModCurrency
  getModCost
  mkWeaponStates
  equipCurWeapon
  unequipCurWeapon
  equipCurBelt
  getUnitSlotsPresetNonUpdatable
  getUnitBeltsNonUpdatable
  calcOverloadInfo
  fixCurPresetOverload
}
