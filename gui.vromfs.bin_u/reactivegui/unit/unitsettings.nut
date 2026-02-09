from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { object_to_json_string, parse_json } = require("json")
let { isEqual } = require("%sqstd/underscore.nut")
let { isDataBlock, eachParam, eachBlock } = require("%sqstd/datablock.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { decalTblToBlk, decalBlkToTbl } = require("%appGlobals/decalBlkSerializer.nut")
let { getDebugUserSettings } = require("%rGui/debugTools/debugSavedData.nut")


const SAVE_ID = "unitSettings"
const DECALS_SAVE_ID = "decalsPresets"

let loadedSettings = Watched({})
let loadedDecals = Watched({})

const DEF_SKIN = "default"
let skinIdToBlk = { [""] = DEF_SKIN }
let skinIdFromBlk = { [DEF_SKIN] = "" }

function loadUnitSettings(unitName) {
  let debugSettings = getDebugUserSettings(unitName)
  if (debugSettings != null)
    return debugSettings

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
  allBlk[getTagsUnitName(unitName)] = settings.len() == 0 ? "" : object_to_json_string(settings)
  eventbus_send("saveProfile", {})
}

function loadSettingsOnce(unitNameExt) {
  let unitName = getTagsUnitName(unitNameExt ?? "")
  if (loadedSettings.get()?[unitName] == null && unitName != "")
    loadedSettings.mutate(@(v) v.$rawset(unitName, loadUnitSettings(unitName)))
}

function loadUnitDecals(unitName) {
  let blk = get_local_custom_settings_blk()
  let dPresetsBlk = blk?[DECALS_SAVE_ID][unitName]
  if (!isDataBlock(dPresetsBlk))
    return {}

  let res = {}
  eachBlock(dPresetsBlk, function(b) {
    let skin = b.getBlockName()
    res[skinIdFromBlk?[skin] ?? skin] <- decalBlkToTbl(b)
  })
  return res
}

function saveUnitDecals(unitNameExt, decalPresets) {
  let allBlk = get_local_custom_settings_blk().addBlock(DECALS_SAVE_ID)
  let unitName = getTagsUnitName(unitNameExt)
  if (decalPresets.len() == 0) {
    if (unitName in allBlk) {
      allBlk.removeBlock(unitName)
      eventbus_send("saveProfile", {})
    }
    return
  }

  let dBlk = allBlk.addBlock(unitName)
  dBlk.clearData()
  foreach (skin, preset in decalPresets)
    dBlk[skinIdToBlk?[skin] ?? skin] = decalTblToBlk(preset)
  eventbus_send("saveProfile", {})
}

function loadDecalsOnce(unitNameExt) {
  let unitName = getTagsUnitName(unitNameExt ?? "")
  if (loadedDecals.get()?[unitName] == null && unitName != "")
    loadedDecals.mutate(@(v) v.$rawset(unitName, loadUnitDecals(unitName)))
}

function resetUnitSettings(unitNameExt) {
  let unitName = getTagsUnitName(unitNameExt)
  if (isOnlineSettingsAvailable.get()) {
    saveUnitSettings(unitName, {})
    saveUnitDecals(unitName, {})
  }
  loadedSettings.mutate(@(v) v.$rawset(unitName, {}))
  loadedDecals.mutate(@(v) v.$rawset(unitName, {}))
}

function applyCompatibility() {
  let fullBlk = get_local_custom_settings_blk()
  let sBlk = fullBlk?[SAVE_ID]
  if (!isDataBlock(sBlk) || DECALS_SAVE_ID in fullBlk)
    return

  let decalsBlk = fullBlk.addBlock(DECALS_SAVE_ID)
  let upd = {}
  eachParam(sBlk, function(str, id) {
    if (type(str) != "string" || str == "")
      return
    local data = null
    try {
      data = parse_json(str)
    }
    catch(e) {
      logerr($"Failed to load unit settings data")
    }
    let { decalsPresets = null } = data
    if (decalsPresets == null)
      return
    let udBlk = decalsBlk.addBlock(id)
    foreach (skin, preset in decalsPresets)
      udBlk[skinIdToBlk?[skin] ?? skin] = decalTblToBlk(preset)

    data.$rawdelete("decalsPresets")
    upd[id] <- data.len() == 0 ? "" : object_to_json_string(data)
  })

  foreach (id, str in upd)
    if (str != "")
      sBlk[id] = str
    else
      sBlk.removeParam(id)
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
  let unitSettings = Computed(@() loadedSettings.get()?[getTagsUnitName(unitNameW.get() ?? "")])
  loadSettingsOnce(unitNameW.get())
  unitSettings.subscribe(@(v) v != null ? null : loadSettingsOnce(unitNameW.get())) 
  function updateUnitSettings(ovr) {
    let unitName = getTagsUnitName(unitNameW.get() ?? "")
    let newValue = (unitSettings.get() ?? {}).__merge(ovr)
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
  return loadedSettings.get()?[getTagsUnitName(unitName ?? "")].isAuto ?? false
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
  return loadedSettings.get()?[getTagsUnitName(unitName ?? "")].tags ?? {}
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
  return loadedSettings.get()?[getTagsUnitName(unitName ?? "")].weaponPreset ?? []
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
  return loadedSettings.get()?[getTagsUnitName(unitName ?? "")].belts ?? {}
}

function mkSavedWeaponPresets(unitNameW) {
  let { unitSettings, updateUnitSettings } = mkUnitSettingsWatch(unitNameW)
  let savedWeaponPresets = Computed(@() unitSettings.get()?.savedWeaponPresets ?? [])
  let setSavedWeaponPresets = @(presets) isEqual(presets, savedWeaponPresets.get()) ? null
    : updateUnitSettings({ savedWeaponPresets = presets })
  return { savedWeaponPresets, setSavedWeaponPresets }
}

function mkSeenMods(unitNameW) {
  let { unitSettings, updateUnitSettings } = mkUnitSettingsWatch(unitNameW)
  let seenUnitMods = Computed(@() unitSettings.get()?.seenMods ?? {})
  let setSeenUnitMods = @(seenMods) isEqual(seenMods, seenUnitMods.get()) ? null
    : updateUnitSettings({ seenMods })
  return { seenUnitMods, setSeenUnitMods }
}

function mkDecalsPresets(unitNameW) {
  let unitDecals = Computed(@() loadedDecals.get()?[getTagsUnitName(unitNameW.get() ?? "")])
  loadDecalsOnce(unitNameW.get())
  unitDecals.subscribe(@(v) v != null ? null : loadSettingsOnce(unitNameW.get())) 
  function setDecalsPresets(presets) {
    let unitName = getTagsUnitName(unitNameW.get() ?? "")
    if (unitName == "")
      return
    if (isOnlineSettingsAvailable.get())
      saveUnitDecals(unitName, presets)
    loadedDecals.mutate(@(v) v.$rawset(unitName, presets))
  }
  return {
    decalsPresets = Computed(@() unitDecals.get() ?? {}),
    setDecalsPresets
  }
}

function getDecalsPresets(unitName) {
  loadDecalsOnce(unitName)
  return loadedDecals.get()?[getTagsUnitName(unitName ?? "")] ?? {}
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
  mkSavedWeaponPresets
  mkSeenMods
  mkDecalsPresets
  getDecalsPresets
  resetUnitSettings
}