from "%globalsDarg/darg_library.nut" import *

let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { mkWeaponPreset, mkChosenBelts } = require("%rGui/unit/unitSettings.nut")
let { getEquippedWeapon, mkWeaponBelts, isBeltWeapon, getEquippedBelt, mkWeaponStates,
  calcOverloadInfo, getEqippedWithoutOverload
} = require("%rGui/unitMods/unitModsSlotsState.nut")
let { sendPlayerActivityToServer } = require("playerActivity.nut")
let { selSlot, hasRespawnSeparateSlots, curUnitsAvgCostWp } = require("respawnState.nut")


let selectedBeltWeaponId = Watched(null)
let selectedBeltCardIdx = Watched(null)

let selectedWSlotIdx = Watched(null)
let selectedWCardIdx = Watched(null)

let isSecondaryWeapChoiceOpened = Computed(@() selectedWSlotIdx.get() != null)
let canShowChooseBulletWnd = Computed(@() selectedWSlotIdx.get() != null || selectedBeltWeaponId.get() != null)

let curUnit = Computed(@() hasRespawnSeparateSlots.get() && canShowChooseBulletWnd.get() ? selSlot.get() : null)
let unitName = Computed(@() curUnit.get()?.name)
let curMods = Computed(@() curUnit.get()?.mods)
let curModPresetCfg = Computed(@() curUnit.get()?.modPresetCfg)
let curUnitAllModsCost = Computed(function() {
  let { costWp = 0, modCostPart = 0.0, rank = 0 } = curUnit.get()
  if (modCostPart <= 0)
    return 0
  let cost = costWp > 0 ? costWp : (curUnitsAvgCostWp.get()?[rank] ?? 0)
  return modCostPart.tofloat() * cost
})

let { weaponPreset, setWeaponPreset } = mkWeaponPreset(unitName)
let { chosenBelts, setChosenBelts } = mkChosenBelts(unitName)

let allWSlots = Computed(@() unitName.get() == null ? [] : loadUnitWeaponSlots(unitName.get()))
let equippedWeaponsBySlots = Computed(@()
  allWSlots.get().map(@(wSlot, idx) getEquippedWeapon(weaponPreset.get(), idx, wSlot?.wPresets ?? {}, curMods.get())))

let selectedSlotWeaponName = Computed(@() equippedWeaponsBySlots.get()?[selectedWSlotIdx.get()].name)

let overloadInfo = Computed(@() !isSecondaryWeapChoiceOpened.get() || unitName.get() == null ? null
  : calcOverloadInfo(unitName.get(), equippedWeaponsBySlots.get()))

function fixCurPresetOverload() {
  if (unitName.get() == null)
    return
  let preset = getEqippedWithoutOverload(unitName.get(), equippedWeaponsBySlots.get())
    .map(@(v) v?.name ?? "")
  setWeaponPreset(preset)
}

let beltSlotsByGroup = Computed(function() {
  let allSlots = []
  let courseSlots = []
  let turretSlots = []
  let addedBelts = {}
  let mods = curMods.get()
  foreach (idx, wSlot in allWSlots.get()) {
    let weapon = getEquippedWeapon(weaponPreset.get(), idx, wSlot?.wPresets ?? {}, mods)
    if (weapon == null)
      continue
    foreach (w in weapon.weapons) {
      let { weaponId } = w
      if (weaponId in addedBelts)
        addedBelts[weaponId].count++
      else if (isBeltWeapon(w)) {
        let list = w.turrets > 0 ? turretSlots : courseSlots
        let equipped = getEquippedBelt(chosenBelts.get(), weaponId, mkWeaponBelts(unitName.get(), w), mods)
        let beltW = w.__merge({
          count = 1
          equipped
          caliber = equipped?.caliber ?? 0
        })
        allSlots.append(beltW)
        list.append(beltW)
        addedBelts[weaponId] <- beltW
      }
    }
  }
  return { allSlots, courseSlots, turretSlots }
})
let beltSlots = Computed(@() beltSlotsByGroup.get().allSlots)
let courseBeltSlots = Computed(@() beltSlotsByGroup.get()?.courseSlots ?? [])
let turretBeltSlots = Computed(@() beltSlotsByGroup.get()?.turretSlots ?? [])

let selectedBeltSlot = Computed(@() beltSlots.get().findvalue(@(cbl) cbl.weaponId == selectedBeltWeaponId.get()))

let selectedWSlot = Computed(@() allWSlots.get()?[selectedWSlotIdx.get()])

let wCards = Computed(function() {
  let { wPresets = {}, wPresetsOrder = {} } = selectedWSlot.get()
  return wPresetsOrder.map(@(id, idx) wPresets[id].__merge({ slotIdx = idx }))
})
let selectedWCard = Computed(@() wCards.get()?[selectedWCardIdx.get()])
let selectedWCardStates = mkWeaponStates(selectedWCard, curModPresetCfg, curUnit)

let beltCards = Computed(function() {
  let beltSlot = selectedBeltSlot.get()
  let uName = unitName.get()
  let curWeapons = mkWeaponBelts(uName, beltSlot)
  if (curWeapons.len() == 0)
    return []
  let bulletsOrder = getUnitTagsCfg(uName)?.bulletsOrder[beltSlot?.weaponId] ?? [""]
  return bulletsOrder
    .map(@(id) curWeapons?[id])
    .filter(@(v) v != null)
    .map(@(bc, idx) bc.__merge({ slotIdx = idx }))
})
let selectedBeltCard = Computed(@() beltCards.get()?[selectedBeltCardIdx.get()])
let selectedBeltCardStates = mkWeaponStates(selectedBeltCard, curModPresetCfg, curUnit)

function closeWnd() {
  selectedWSlotIdx.set(null)
  selectedWCardIdx.set(null)
  selectedBeltWeaponId.set(null)
  selectedBeltCardIdx.set(null)
  sendPlayerActivityToServer()
}

function equipWeapon(slotIdx, weaponId) {
  let preset = clone weaponPreset.get()
  if (slotIdx >= preset.len())
    preset.resize(slotIdx + 1, "")
  preset[slotIdx] = weaponId
  setWeaponPreset(preset)
}

let equipSelWeapon = @() equipWeapon(selectedWSlotIdx.get(), selectedWCard.get()?.name ?? "")
let unequipSelWeapon = @() equipWeapon(selectedWSlotIdx.get(), "")

function applyBelt(weaponId, beltId) {
  if (chosenBelts.get()?[weaponId] != beltId)
    setChosenBelts(chosenBelts.get().__merge({ [weaponId] = beltId }))
}

function selectWeaponCard(slotIdx) {
  selectedWCardIdx.set(slotIdx == selectedWCardIdx.get() ? null : slotIdx)
  sendPlayerActivityToServer()
}

function selectBeltCard(slotIdx) {
  selectedBeltCardIdx.set(slotIdx)
  sendPlayerActivityToServer()
}

function selectWeaponSlot(slotIdx) {
  closeWnd()
  selectedWSlotIdx.set(slotIdx)
}

function selectBeltSlot(weaponId) {
  closeWnd()
  selectedBeltWeaponId.set(weaponId)
}

canShowChooseBulletWnd.subscribe(@(v) !v ? closeWnd() : null)

return {
  selectedBeltWeaponId
  selectedBeltCardIdx
  selectedBeltSlot
  selectedBeltCard
  selectedBeltCardStates

  selectedWSlotIdx
  selectedWCardIdx
  selectedWSlot
  selectedWCard
  selectedWCardStates

  canShowChooseBulletWnd

  selectedSlotWeaponName

  weaponPreset
  setWeaponPreset
  chosenBelts
  setChosenBelts

  curUnit
  unitName
  curMods
  curUnitAllModsCost
  curModPresetCfg

  allWSlots
  equippedWeaponsBySlots
  overloadInfo
  fixCurPresetOverload
  beltSlots
  courseBeltSlots
  turretBeltSlots

  wCards
  beltCards

  closeWnd
  applyBelt
  equipSelWeapon
  unequipSelWeapon
  selectBeltSlot
  selectBeltCard
  selectWeaponSlot
  selectWeaponCard
}