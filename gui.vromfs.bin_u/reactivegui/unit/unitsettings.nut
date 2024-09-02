from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { object_to_json_string, parse_json } = require("json")
let { isEqual } = require("%sqstd/underscore.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")

const SAVE_ID = "unitSettings"

let loadedSettings = Watched({})

function loadUnitSettings(unitName) {
  let blk = get_local_custom_settings_blk()
  let settingsString = blk?[SAVE_ID][unitName]
  if (type(settingsString) != "string" || settingsString == "")
    return {}

  local res = {}
  try {
    res = parse_json(settingsString)
  }
  catch(e) {
    logerr($"Failed to load unit settings data")
  }
  return res
}

function saveUnitSettings(unitName, settings) {
  let blk = get_local_custom_settings_blk()
  let allBlk = blk.addBlock(SAVE_ID)
  allBlk[unitName] = settings.len() == 0 ? "" : object_to_json_string(settings)
  eventbus_send("saveProfile", {})
}

let function loadSettingsOnce(unitName) {
  if (loadedSettings.get()?[unitName] == null && (unitName ?? "") != "")
    loadedSettings.mutate(@(v) v.$rawset(unitName, loadUnitSettings(unitName)))
}

let OLD_SAVE_ID = "skinTuning" //24.05.2024
function applyCompatibility() {
  let blk = get_local_custom_settings_blk()
  if (OLD_SAVE_ID not in blk)
    return
  let newBlk = blk.addBlock(SAVE_ID)
  newBlk.setFrom(blk[OLD_SAVE_ID])
  blk.removeBlock(OLD_SAVE_ID)
}

if (isOnlineSettingsAvailable.get())
  applyCompatibility()

isOnlineSettingsAvailable.subscribe(function(s) {
  applyCompatibility()
  if (loadedSettings.get().len() == 0)
    return
  loadedSettings.set(loadedSettings.get().map(@(_, unitName) s ? loadUnitSettings(unitName) : null))
})

function mkUnitSettingsWatch(unitNameW) {
  let unitSettings = Computed(@() loadedSettings.get()?[unitNameW.get()] ?? {})
  loadSettingsOnce(unitNameW.get())
  unitSettings.subscribe(@(v) v.len() != 0 ? null : loadSettingsOnce(unitNameW.get())) //subscribe not on unitNameW only to allow unitSettings correct remove from memore when unused
  function updateUnitSettings(ovr) {
    let unitName = unitNameW.get()
    let newValue = unitSettings.get().__merge(ovr)
    if (isOnlineSettingsAvailable.get())
      saveUnitSettings(unitName, newValue)
    loadedSettings.mutate(@(v) v.$rawset(unitName, newValue))
  }
  return { unitSettings, updateUnitSettings }
}

function mkIsAutoSkin(unitNameW) {
  let { unitSettings, updateUnitSettings } = mkUnitSettingsWatch(unitNameW)
  let isAutoSkin = Computed(@() unitSettings.get()?.isAuto ?? false)
  let setAutoSkin = @(isAuto) isAuto == isAutoSkin.get() ? null
    : updateUnitSettings({ isAuto })
  return { isAutoSkin, setAutoSkin }
}

function isAutoSkin(unitName) {
  loadSettingsOnce(unitName)
  return loadedSettings.get()?[unitName].isAuto ?? false
}

function mkSkinCustomTags(unitNameW) {
  let { unitSettings, updateUnitSettings } = mkUnitSettingsWatch(unitNameW)
  let skinCustomTags = Computed(@() unitSettings.get()?.tags ?? {})
  let setSkinCustomTags = @(tags) isEqual(tags, skinCustomTags.get()) ? null
    : updateUnitSettings({ tags })
  return { skinCustomTags, setSkinCustomTags }
}

function getSkinCustomTags(unitName) {
  loadSettingsOnce(unitName)
  return loadedSettings.get()?[unitName].tags ?? {}
}

function mkWeaponPreset(unitNameW) {
  let { unitSettings, updateUnitSettings } = mkUnitSettingsWatch(unitNameW)
  let weaponPreset = Computed(@() unitSettings.get()?.weaponPreset ?? [])
  let setWeaponPreset = @(preset) isEqual(preset, weaponPreset.get()) ? null
    : updateUnitSettings({ weaponPreset = preset })
  return { weaponPreset, setWeaponPreset }
}

function getWeaponPreset(unitName) {
  loadSettingsOnce(unitName)
  return loadedSettings.get()?[unitName].weaponPreset ?? []
}

function mkChosenBelts(unitNameW) {
  let { unitSettings, updateUnitSettings } = mkUnitSettingsWatch(unitNameW)
  let chosenBelts = Computed(@() unitSettings.get()?.belts ?? {})
  let setChosenBelts = @(belts) isEqual(belts, chosenBelts.get()) ? null
    : updateUnitSettings({ belts })
  return { chosenBelts, setChosenBelts }
}

function getChosenBelts(unitName) {
  loadSettingsOnce(unitName)
  return loadedSettings.get()?[unitName].belts ?? {}
}

return {
  mkUnitSettingsWatch
  mkIsAutoSkin
  isAutoSkin
  mkSkinCustomTags
  getSkinCustomTags
  mkWeaponPreset
  getWeaponPreset
  mkChosenBelts
  getChosenBelts
}