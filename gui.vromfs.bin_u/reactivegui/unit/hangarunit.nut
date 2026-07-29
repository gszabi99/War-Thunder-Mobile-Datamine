from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
from "blkGetters" import get_unittags_blk
from "console" import register_command
require("%rGui/onlyAfterLogin.nut")
let logH = log_with_prefix("[HANGAR] ")
let DataBlock = require("DataBlock")
let { set_weapon_visual_custom_blk, apply_skin_decals_blk, set_default_skin_decals } = require("unitCustomization")
let { eventbus_subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { hangar_load_model_with_skin, hangar_move_cam_to_unit_place,
  hangar_get_current_unit_name, hangar_get_loaded_unit_name, change_background_models_list_with_skin,
  change_one_background_model_with_skin, hangar_get_current_unit_skin, get_current_background_models_list,
  hangar_force_reload_model, set_allowed_decals_count
} = require("hangar")
let { rnd_int } = require("dagor.random")
let { prevIfEqual, isEqual } = require("%sqstd/underscore.nut")
let { decalTblToBlk } = require("%appGlobals/decalBlkSerializer.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { isInMenu, isInMpSession, isInLoadingScreen, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { mkHasUnitsResources } = require("%appGlobals/updater/addonsState.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { mkWeaponPreset, mkDecalsPresets, getDecalsPresets } = require("%rGui/unit/unitSettings.nut")
let { getEqippedWithoutOverload, getEquippedWeapon } = require("%rGui/unitMods/equippedSecondaryWeapons.nut")
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")

const MAX_DECAL_SLOTS_COUNT = 4

let hasBgUnitsByCamp = {
  tanks = true
  air = true
}

let isHangarUnitLoaded = mkWatched(persist, "isHangarUnitLoaded", false)
let loadedInfo = Watched({
  name = hangar_get_current_unit_name()
  skin = hangar_get_current_unit_skin()
})
let loadedHangarUnitName = Computed(@() loadedInfo.get().name)
let loadedHangarUnitSkin = Computed(@() loadedInfo.get().skin)
let hangarUnitData = mkWatched(persist, "hangarUnitData", null)
let hangarUnitDataBackup = mkWatched(persist, "hangarUnitDataBackup", null)
let hangarUnitName = Computed(@() hangarUnitData.get()?.name ?? loadedHangarUnitName.get() ?? "")
let lastHangarUnitBattleData = mkWatched(persist, "hangarUnitBattleData", null)
let isCustomHangarUnitData = Computed(@() hangarUnitData.get()?.custom != null)
local wasLoadBgModelsAfterLoading = false

let mainHangarUnit = Computed(function() {
  let { name = loadedHangarUnitName.get(), custom = null } = hangarUnitData.get()
  return custom ?? campMyUnits.get()?[name] ?? campUnitsCfg.get()?[name]
})

let mainHangarUnitName = Computed(@() mainHangarUnit.get()?.name)
let { weaponPreset } = mkWeaponPreset(mainHangarUnitName)

let hangarUnitPreset = Computed(function() {
  let { name = null, mods = null } = mainHangarUnit.get()
  if (name == null)
    return null
  let weaponSlots = loadUnitWeaponSlots(name)
  if (weaponSlots.len() == 0)
    return null
  let equippedWeaponsBySlots = weaponSlots
    .map(@(slot, idx) getEquippedWeapon(weaponPreset.get(), idx, slot?.wPresets ?? {}, mods))
  return getEqippedWithoutOverload(name, equippedWeaponsBySlots).map(@(a) a?.name ?? "")
})

let hangarUnit = Computed(function() {
  let mainUnit = mainHangarUnit.get()
  let { name = loadedHangarUnitName.get() } = hangarUnitData.get()
  if (mainUnit == null || name == mainUnit.name)
    return mainUnit
  return mainUnit
})

let nameAndSkin = @(name, skin, currentSkins = null, defSkin = "") {
  name
  skin = skin ?? currentSkins?[name] ?? defSkin 
}

let hangarBgUnits = Computed(function(prev) {
  let { bgUnits = [] } = hangarUnitData.get()
  if (bgUnits.len() > 0)
    return prevIfEqual(prev, bgUnits.map(@(u) nameAndSkin(u, "")))

  let hUnit = hangarUnit.get()
  if (hUnit == null || !hasBgUnitsByCamp?[hUnit.campaign])
    return []

  return isCustomHangarUnitData.get() || curSlots.get().findvalue(@(v) v.name == hUnit.name) == null
    ? []
    : prevIfEqual(prev,
        curSlots.get().reduce(function(res, v) {
          if (v.name == "" || v.name == hUnit.name)
            return res
          let unit = campMyUnits.get()?[v.name] ?? campUnitsCfg.get()?[v.name]
          return unit == null ? res
            : res.append(nameAndSkin(unit.name, unit?.skin, unit?.currentSkins, unit?.isUpgraded ? "upgraded" : ""))
        }, []))
})

let hangarUnitSkin = Computed(@() hangarUnitData.get()?.skin
  ?? hangarUnit.get()?.skin
  ?? hangarUnit.get()?.currentSkins[hangarUnit.get()?.name] 
  ?? (hangarUnit.get()?.isUpgraded ? "upgraded" : ""))

let downloadUnitNames = Computed(@() hangarUnitName.get() == null ? []
  : [hangarUnitName.get()].extend(hangarBgUnits.get().map(@(s) (s.name))))
let hasHangarUnitResources = mkHasUnitsResources(downloadUnitNames)
let canReloadModel = keepref(Computed(@() !isInBattle.get() && !isInLoadingScreen.get()))

let { decalsPresets } = mkDecalsPresets(hangarUnitName)
let hangarUnitDecalPreset = keepref(Computed(@() decalsPresets.get()?[hangarUnitSkin.get()]))

let hangarUnitDecalSlotsCount = Computed(function() {
  if (hangarUnit.get() == null)
    return MAX_DECAL_SLOTS_COUNT

  let { name, isUpgraded = false, isPremium = false, decalSlotsCount = 2 } = hangarUnit.get()
  let { decalSkinCfg = {} } = serverConfigs.get()
  let { skins = {} } = servProfile.get()

  let unitDecalsList = decalSkinCfg?[name][hangarUnitSkin.get()] ?? []
  let isSkinReceived = hangarUnitSkin.get() in skins

  return isUpgraded || isPremium || havePremium.get() || (!isSkinReceived && unitDecalsList.len() > 0)
    ? MAX_DECAL_SLOTS_COUNT
    : decalSlotsCount
})

let hangarUnitHasLockedPremDecals = Computed(@() hangarUnitDecalSlotsCount.get() < MAX_DECAL_SLOTS_COUNT)

function setHangarUnitWeaponPreset(unitName, preset) {
  if (unitName == null)
    return
  let blk = DataBlock()
  blk.name = ""
  foreach (slot, weaponId in preset) {
    if (slot == 0 || weaponId == "")
      continue
    let weaponBlk = blk.addNewBlock("Weapon")
    weaponBlk.preset = weaponId
    weaponBlk.slot = slot
  }
  set_weapon_visual_custom_blk(unitName, blk)
}

function setHangarUnitDecalPreset(unitName, skin, preset) {
  if (unitName == null)
    return
  apply_skin_decals_blk(unitName, skin, decalTblToBlk(preset))
}

function loadModel(unitName, skin, weapPreset, availableDecalSlotsCount) {
  if ((unitName ?? "") == "" && hangar_get_current_unit_name() == "") {
    
    unitName = (campMyUnits.get().findvalue(@(_) true) ?? campUnitsCfg.get().findvalue(@(_) true))?.name
    
    skin = ""
  }

  if ((unitName ?? "") == "")
    return

  if (!hasHangarUnitResources.get() && !isOfflineMenu) {
    hangar_move_cam_to_unit_place(unitName)
    return
  }

  let preset = getDecalsPresets(unitName)?[skin]
  if (preset != null)
    setHangarUnitDecalPreset(unitName, skin, preset)
  else
    set_default_skin_decals(true)

  set_allowed_decals_count(availableDecalSlotsCount)

  hangar_load_model_with_skin(unitName, false, skin)
  if (weapPreset != null)
    setHangarUnitWeaponPreset(unitName, weapPreset)
}

let loadCurrentHangarUnitModel = @() loadModel(hangarUnitName.get(), hangarUnitSkin.get(), hangarUnitPreset.get(),
  hangarUnitDecalSlotsCount.get())

loadCurrentHangarUnitModel()
hangarUnitName.subscribe(@(_) deferOnce(loadCurrentHangarUnitModel))
hangarUnitSkin.subscribe(@(_) deferOnce(loadCurrentHangarUnitModel))
hangarUnitPreset.subscribe(@(_) deferOnce(loadCurrentHangarUnitModel))
hangarUnitDecalPreset.subscribe(@(_) deferOnce(loadCurrentHangarUnitModel))
hangarUnitDecalSlotsCount.subscribe(@(_) deferOnce(loadCurrentHangarUnitModel))

isInMpSession.subscribe(function(v) {
  if (v || !isInMenu.get() || hangar_get_current_unit_name() == loadedInfo.get().name)
    return
  loadedInfo.set({
    name = hangar_get_current_unit_name()
    skin = hangar_get_current_unit_skin()
  })
  loadCurrentHangarUnitModel()
})

function reloadAllBgModels() {
  let unitsList = hasHangarUnitResources.get() ? hangarBgUnits.get() : []
  logH("load hangar bg units: ", unitsList.map(@(v) v.name))
  change_background_models_list_with_skin(hangarUnitName.get(), unitsList)
}

function loadBGModels() {
  let bgUnits = hangarBgUnits.get()
  let { name, skin } = loadedInfo.get()
  if (name == null || name != hangarUnitName.get() || skin != hangarUnitSkin.get()) {
    if (!hasHangarUnitResources.get())
      reloadAllBgModels() 
    return 
  }

  if (!wasLoadBgModelsAfterLoading) {
    reloadAllBgModels()
    wasLoadBgModelsAfterLoading = true
    return
  }

  local wasBgUnits = get_current_background_models_list()
  if (wasBgUnits.len() != bgUnits.len()) {
    reloadAllBgModels()
    return
  }

  local changedIdx = null
  foreach(i, u in wasBgUnits)
    if (u.name != bgUnits[i].name || u.skin != bgUnits[i].skin) {
      if (changedIdx == null)
        changedIdx = i
      else {
        reloadAllBgModels()
        return
      }
    }

  if (changedIdx == null)
    return

  logH($"Change one hangar bg unit from {wasBgUnits[changedIdx].name} to {bgUnits[changedIdx].name}")
  change_one_background_model_with_skin(wasBgUnits[changedIdx].name, bgUnits[changedIdx].name, bgUnits[changedIdx].skin)
}
deferOnce(loadBGModels)

loadedInfo.subscribe(@(_) deferOnce(loadBGModels))
hangarBgUnits.subscribe(@(_) deferOnce(loadBGModels))

isInLoadingScreen.subscribe(function(v) {
  if (v)
    wasLoadBgModelsAfterLoading = false
})

let setHangarUnit = @(unitName) hangarUnitData.set({ name = unitName ?? "" })

let setHangarUnitWithSkin = @(name, skin) hangarUnitData.set({ name, skin })

function selectMainUnitIdx(bgUnits, needRandomize, chosenIdx) {
  if (chosenIdx == null)
    return needRandomize ? rnd_int(0, bgUnits.len() - 1) : 0
  return chosenIdx < bgUnits.len() ? chosenIdx : rnd_int(0, bgUnits.len() - 1)
}

function setHangarUnitGroup(unitList, needRandomize, chosenIdx = null) {
  if (unitList.len() == 0)
    return null
  let bgUnits = clone unitList
  let mainIdx = selectMainUnitIdx(bgUnits, needRandomize, chosenIdx)
  let main = bgUnits.remove(mainIdx)
  hangarUnitData.set({ name = main, bgUnits })
  return mainIdx
}

function setCustomHangarUnit(customUnit) {
  if (hangarUnitDataBackup.get() == null)
    hangarUnitDataBackup.set(hangarUnitData.get())
  hangarUnitData.set({ name = customUnit.name, custom = customUnit })
}

function resetCustomHangarUnit() {
  if (hangarUnitDataBackup.get()) {
    hangarUnitData.set(hangarUnitDataBackup.get())
    hangarUnitDataBackup.set(null)
  }
}

let hangarBattleData = Computed(function(prev) {
  if (mainHangarUnit.get() == null)
    return null
  let { name, country = "", unitType = "", mods = null, modPreset = "",
    isUpgraded = false, isPremium = false
  } = mainHangarUnit.get()

  let cfgMods = serverConfigs.get()?.unitModPresets[modPreset] ?? {}
  let modifications = mods != null
      ? mods.filter(@(has, id) has && id in cfgMods)
          .map(@(_) 1)
    : isPremium || isUpgraded
      ? cfgMods.map(@(_) 1) 
    : {}
  return prevIfEqual(prev, {
    userId = myUserId.get()
    modifications
    unit = {
      name
      country
      unitType
      isUpgraded
      isPremium = isPremium || isUpgraded
      weapons = { [$"{name}_default"] = true }
      attributes = {} 
      platoonUnits = curSlots.get()
        .filter(@(v) v.name != "" && v.name != name)
        .map(@(p) {
          name = p.name
          weapons = { [$"{p.name}_default"] = true }
        })
    }
  })
})

let needReloadHangarBattleData = Computed(function() {
  let bd = hangarBattleData.get()
  let { name = null } = bd?.unit
  let lastName = lastHangarUnitBattleData.get()?.unit.name ?? name
  let hangarUnitDataName = hangarUnitData.get()?.name != null ? hangarUnitData.get().name : loadedHangarUnitName.get()
  return name != null && name == lastName
    && hangarUnitSkin.get() == loadedHangarUnitSkin.get()
    && hangarUnitDataName == loadedHangarUnitName.get()
    && !isEqual(bd, lastHangarUnitBattleData.get())
})

function reloadModelIdNeed() {
  if (!needReloadHangarBattleData.get())
    return
  log("[HANGAR_BATTLE_DATA] request hangar_force_reload_model on battle data change")
  hangar_force_reload_model()
}

hangarBattleData.subscribe(@(_) deferOnce(reloadModelIdNeed))
needReloadHangarBattleData.subscribe(@(_) deferOnce(reloadModelIdNeed))

function onReloadModel() {
  if (!canReloadModel.get())
    return
  loadCurrentHangarUnitModel()
  reloadAllBgModels()
}
canReloadModel.subscribe(@(_) deferOnce(onReloadModel))
hasHangarUnitResources.subscribe(@(_) deferOnce(onReloadModel))

eventbus_subscribe("onHangarModelStartLoad", @(_) isHangarUnitLoaded.set(false))

eventbus_subscribe("onHangarModelLoaded", function(_) {
  if (hangar_get_loaded_unit_name() != hangar_get_current_unit_name())
    return
  isHangarUnitLoaded.set(true)
  let lInfo = {
    name = hangar_get_current_unit_name()
    skin = hangar_get_current_unit_skin()
  }

  if (!isEqual(loadedInfo.get(), lInfo))
    loadedInfo.set(lInfo)
  if (lInfo.name != hangarUnitName.get() || lInfo.skin != hangarUnitSkin.get()) {
    log("Reload hangar unit because of wrong skin")
    loadCurrentHangarUnitModel()
  }
})

register_command(
  function(unitName) {
    if (unitName not in get_unittags_blk())
      return console_print($"Unit {unitName} does not exist in the unittags.blk") 
    setHangarUnit(unitName)
    console_print("Done") 
  },
  "hangar.set_unit")

register_command(
  function(unitName, skinName) {
    if (unitName not in get_unittags_blk())
      return console_print($"Unit {unitName} does not exist in the unittags.blk") 
    setHangarUnitWithSkin(unitName, skinName)
    console_print("Done") 
  },
  "hangar.set_unit_with_skin")

return {
  loadedHangarUnitName 
  loadedHangarUnitSkin
  hangarUnitName 
  hangarUnit 
  hangarUnitSkin
  hangarUnitDataBackup

  setHangarUnit  
  setHangarUnitWithSkin
  setHangarUnitGroup
  setCustomHangarUnit  
  resetCustomHangarUnit 
  isHangarUnitLoaded

  mainHangarUnit
  mainHangarUnitName
  lastHangarUnitBattleData
  hangarBattleData
  needReloadHangarBattleData

  hasHangarUnitResources
  hasBgUnitsByCamp

  MAX_DECAL_SLOTS_COUNT
  hangarUnitDecalSlotsCount
  hangarUnitHasLockedPremDecals
}