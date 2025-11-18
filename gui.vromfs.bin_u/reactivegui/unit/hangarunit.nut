from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
require("%rGui/onlyAfterLogin.nut")
let DataBlock = require("DataBlock")
let { set_weapon_visual_custom_blk, apply_skin_decals_blk, set_default_skin_decals } = require("unitCustomization")
let { eventbus_subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { hangar_load_model_with_skin, hangar_move_cam_to_unit_place,
  hangar_get_current_unit_name, hangar_get_loaded_unit_name, change_background_models_list_with_skin,
  change_one_background_model_with_skin, hangar_get_current_unit_skin, get_current_background_models_list,
  hangar_force_reload_model, set_allowed_decals_count
} = require("hangar")
let { prevIfEqual, isEqual } = require("%sqstd/underscore.nut")
let { decalTblToBlk } = require("%appGlobals/decalBlkSerializer.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { allMainUnitsByPlatoon } = require("%appGlobals/pServer/allMainUnitsByPlatoon.nut")
let { isInMenu, isInMpSession, isInLoadingScreen, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { mkHasUnitsResources } = require("%appGlobals/updater/addonsState.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { mkWeaponPreset, mkDecalsPresets, getDecalsPresets } = require("%rGui/unit/unitSettings.nut")
let { getEqippedWithoutOverload, getEquippedWeapon } = require("%rGui/unitMods/equippedSecondaryWeapons.nut")
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")

const MAX_DECAL_SLOTS_COUNT = 4

let hasBgUnitsByCamp = {
  tanks = true
  tanks_new = true
}

let isHangarUnitLoaded = mkWatched(persist, "isHangarUnitLoaded", false)
let loadedInfo = Watched({
  name = hangar_get_current_unit_name()
  skin = hangar_get_current_unit_skin()
})
let loadedHangarUnitName = Computed(@() loadedInfo.get().name)
let hangarUnitData = mkWatched(persist, "hangarUnitData", null)
let hangarUnitDataBackup = mkWatched(persist, "hangarUnitDataBackup", null)
let hangarUnitName = Computed(@() hangarUnitData.get()?.name ?? loadedHangarUnitName.get() ?? "")
let lastHangarUnitBattleData = mkWatched(persist, "hangarUnitBattleData", null)
let isCustomHangarUnitData = Computed(@() hangarUnitData.get()?.custom != null)
local wasLoadBgModelsAfterLoading = false

let mainHangarUnit = Computed(function() {
  let { name = loadedHangarUnitName.get(), custom = null } = hangarUnitData.get()
  if (custom == null)
    return campMyUnits.get()?[name] ?? campUnitsCfg.get()?[name]

  if (custom.name not in campUnitsCfg.get()) {
    let mainName = allMainUnitsByPlatoon.get()?[custom.name].name
    if (mainName != null)
      return custom.__merge({ name = mainName })
  }
  return custom
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
  return mainUnit.__merge(mainUnit.platoonUnits.findvalue(@(pu) pu.name == name) ?? {})
})

let nameAndSkin = @(name, skin, currentSkins, defSkin) {
  name = getTagsUnitName(name)
  skin = skin ?? currentSkins?[name] ?? defSkin
}

let hangarBgUnits = Computed(function(prevC) {
  let hUnit = hangarUnit.get()
  if (hUnit == null || !hasBgUnitsByCamp?[hUnit.campaign])
    return []

  if ((hUnit?.platoonUnits.len() ?? 0) == 0)
    return isCustomHangarUnitData.get() || curSlots.get().findvalue(@(v) v.name == hUnit.name) == null
      ? []
      : curSlots.get().reduce(function(res, v) {
          if (v.name == "" || v.name == hUnit.name)
            return res
          let unit = campMyUnits.get()?[v.name] ?? campUnitsCfg.get()?[v.name]
          return unit == null ? res
            : res.append(nameAndSkin(unit.name, unit?.skin, unit?.currentSkins, unit?.isUpgraded ? "upgraded" : ""))
        }, [])

  let skin = hangarUnitData.get()?.skin
  let { platoonUnits, currentSkins = {}, isUpgraded = false } = mainHangarUnit.get()
  let mainName = mainHangarUnit.get().name
  let fgName = hUnit.name
  let allNames = platoonUnits.reduce(@(res, p) res.$rawset(p.name, true), { [mainName] = true })
  let defSkin = isUpgraded ? "upgraded" : ""

  let prev = type(prevC) == "array" ? prevC : get_current_background_models_list()
  if (prev.len() + 1 == allNames.len() && prev.findvalue(@(p) p.name not in allNames) == null) {
    
    let leftNames = clone allNames
    leftNames.$rawdelete(fgName)
    return prev
      .map(function(p) {
        if (p.name not in leftNames)
          return null
        leftNames.$rawdelete(p.name)
        return nameAndSkin(p.name, skin, currentSkins, defSkin)
      })
     .map(function(p) {
       if (p != null)
         return p
       let name = mainName in leftNames ? mainName
         : leftNames.findindex(@(_) true)
       if (name in leftNames)
         leftNames.$rawdelete(name)
       return nameAndSkin(name, skin, currentSkins, defSkin)
     })
  }

  
  let res = platoonUnits.map(@(p) nameAndSkin(p.name, skin, currentSkins, defSkin))
  if (mainName != fgName) {
    let idx = res.findindex(@(p) p.name == fgName)
    if (idx != null)
      res[idx] = nameAndSkin(mainName, skin, currentSkins, defSkin)
  }
  return res
})

let hangarUnitSkin = Computed(@() hangarUnitData.get()?.skin
  ?? hangarUnit.get()?.currentSkins[hangarUnit.get()?.name]
  ?? (hangarUnit.get()?.isUpgraded ? "upgraded" : ""))

let downloadUnitNames = Computed(@() hangarUnit.get() == null ? []
  : [hangarUnit.get().name].extend(hangarBgUnits.get().map(@(s) (s.name))))
let hasHangarUnitResources = mkHasUnitsResources(downloadUnitNames)
let canReloadModel = keepref(Computed(@() !isInBattle.get() && !isInLoadingScreen.get()))

let { decalsPresets } = mkDecalsPresets(hangarUnitName)
let hangarUnitDecalPreset = Computed(@() decalsPresets.get()?[hangarUnitSkin.get()])

let hangarUnitDecalSlotsCount = Computed(function() {
  if (hangarUnit.get() == null)
    return MAX_DECAL_SLOTS_COUNT
  let { isUpgraded = false, isPremium = false, decalSlotsCount = 2 } = hangarUnit.get()
  return isUpgraded || isPremium || havePremium.get() ? MAX_DECAL_SLOTS_COUNT : decalSlotsCount
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
  set_weapon_visual_custom_blk(getTagsUnitName(unitName), blk)
}

function setHangarUnitDecalPreset(unitName, skin, preset) {
  if (unitName == null)
    return
  apply_skin_decals_blk(unitName, skin, decalTblToBlk(preset))
}

function loadModel(unitName, skin, weapPreset, decalPreset, availableDecalSlotsCount) {
  if ((unitName ?? "") == "" && hangar_get_current_unit_name() == "")
    
    unitName = (campMyUnits.get().findvalue(@(_) true) ?? campUnitsCfg.get().findvalue(@(_) true))?.name

  if ((unitName ?? "") == "")
    return

  if (!hasHangarUnitResources.get() && !isOfflineMenu) {
    hangar_move_cam_to_unit_place(getTagsUnitName(unitName))
    return
  }

  let preset = decalPreset ?? getDecalsPresets(getTagsUnitName(unitName))?[skin]
  if (preset != null)
    setHangarUnitDecalPreset(getTagsUnitName(unitName), skin, preset)
  else
    set_default_skin_decals(true)

  set_allowed_decals_count(availableDecalSlotsCount)

  hangar_load_model_with_skin(getTagsUnitName(unitName), skin)
  if (weapPreset != null)
    setHangarUnitWeaponPreset(unitName, weapPreset)
}

let loadCurrentHangarUnitModel = @() loadModel(hangarUnitName.get(), hangarUnitSkin.get(), hangarUnitPreset.get(),
  hangarUnitDecalPreset.get(), hangarUnitDecalSlotsCount.get())

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
  change_background_models_list_with_skin(getTagsUnitName(hangarUnitName.get()),
    hasHangarUnitResources.get() ? hangarBgUnits.get() : [])
}

function loadBGModels() {
  let bgUnits = hangarBgUnits.get()
  let { name, skin } = loadedInfo.get()
  if (name == null || name != getTagsUnitName(hangarUnitName.get()) || skin != hangarUnitSkin.get()) {
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

  change_one_background_model_with_skin(wasBgUnits[changedIdx].name, bgUnits[changedIdx].name, bgUnits[changedIdx].skin)
}
loadBGModels()

loadedInfo.subscribe(@(_) loadBGModels())
hangarBgUnits.subscribe(@(_) loadBGModels())

isInLoadingScreen.subscribe(function(v) {
  if (v)
    wasLoadBgModelsAfterLoading = false
})

let setHangarUnit = @(unitName) hangarUnitData.set({ name = unitName ?? "" })

let setHangarUnitWithSkin = @(name, skin) hangarUnitData.set({ name, skin })

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
  let { country = "", unitType = "", mods = null, modPreset = "",
    isUpgraded = false, isPremium = false, platoonUnits = []
  } = mainHangarUnit.get()

  let name = getTagsUnitName(mainHangarUnit.get().name)
  let cfgMods = serverConfigs.get()?.unitModPresets[modPreset] ?? {}
  let modifications = mods != null
      ? mods.filter(@(has, id) has && id in cfgMods)
          .map(@(_) 1)
    : isPremium || isUpgraded
      ? cfgMods.map(@(_) 1) 
    : {}
  return prevIfEqual(prev, {
    userId = myUserId.get()
    items = modifications 
    modifications
    unit = {
      name
      country
      unitType
      isUpgraded
      isPremium = isPremium || isUpgraded
      weapons = { [$"{name}_default"] = true }
      attributes = {} 
      platoonUnits = platoonUnits.map(@(p) {
        name = p.name
        weapons = { [$"{p.name}_default"] = true }
      })
    }
  })
})

hangarBattleData.subscribe(function(bd) {
  let { name = null } = bd?.unit
  let lastName = lastHangarUnitBattleData.get()?.unit.name ?? name
  let hangarUnitDataName = hangarUnitData.get()?.name != null ? getTagsUnitName(hangarUnitData.get().name) : loadedHangarUnitName.get()
  let needReload = name != null && name == lastName
    && hangarUnitDataName == loadedHangarUnitName.get()
    && !isEqual(bd, lastHangarUnitBattleData.get())
  if (needReload) {
    log("[HANGAR_BATTLE_DATA] request hangar_force_reload_model on battle data change")
    hangar_force_reload_model()
  }
})

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
  if (lInfo.name != getTagsUnitName(hangarUnitName.get()) || lInfo.skin != hangarUnitSkin.get()) {
    log("Reload hangar unit because of wrong skin")
    loadCurrentHangarUnitModel()
  }
})

return {
  loadedHangarUnitName 
  hangarUnitName 
  hangarUnit 
  hangarUnitSkin
  hangarUnitDataBackup

  setHangarUnit  
  setHangarUnitWithSkin
  setCustomHangarUnit  
  resetCustomHangarUnit 
  isHangarUnitLoaded

  mainHangarUnit
  mainHangarUnitName
  lastHangarUnitBattleData
  hangarBattleData

  hasHangarUnitResources
  hasBgUnitsByCamp

  MAX_DECAL_SLOTS_COUNT
  hangarUnitDecalSlotsCount
  hangarUnitHasLockedPremDecals
}