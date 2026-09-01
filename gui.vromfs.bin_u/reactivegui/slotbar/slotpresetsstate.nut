from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send
from "json" import object_to_json_string, parse_json
from "%sqstd/underscore.nut" import isEqual
import "%appGlobals/getTagsUnitName.nut" as getTagsUnitName
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/slots.nut" import curSlots
from "types" import String


const SAVE_ID = "slotSavedPresets"
const SLOT_PRESETS_VERSION_KEY = "slotPresetsVersion"
const ACTUAL_VERSION = 3
const NC_REMOVE_VERSION = 2
let loadedSlotPresets = mkWatched(persist, "loadedSlotPresets", {})

function removeNC(sBlk) {
  let slotBlk = sBlk?[SAVE_ID]
  if (!(slotBlk instanceof String) || slotBlk == "")
    return

  local slotPresets = {}
  try {
    slotPresets = parse_json(slotBlk)
  }
  catch(e) {
    logerr($"Failed to load slot presets data")
  }

  foreach (presets in slotPresets)
    foreach (p in presets)
      if ("presetUnits" in p)
        p.presetUnits = p.presetUnits.map(getTagsUnitName)
  sBlk[SAVE_ID] = object_to_json_string(slotPresets)
}

function removeTanksNew(sBlk) {
  let presetsStr = sBlk?[SAVE_ID]
  if (!(presetsStr instanceof String) || presetsStr.indexof("\"tanks_new\"") == null)
    return
  sBlk[SAVE_ID] = presetsStr.replace("\"tanks_new\"", "\"tanks\"")
}

function applyCompatibility() {
  let sBlk = get_local_custom_settings_blk()
  let version = sBlk?[SLOT_PRESETS_VERSION_KEY] ?? 0
  if (version == ACTUAL_VERSION)
    return

  if (version < NC_REMOVE_VERSION)
    removeNC(sBlk)
  removeTanksNew(sBlk)

  sBlk[SLOT_PRESETS_VERSION_KEY] = ACTUAL_VERSION
  eventbus_send("saveProfile", {})
}

function loadSlotPresets() {
  applyCompatibility()
  let blk = get_local_custom_settings_blk()
  let settingsString = blk?[SAVE_ID]
  local res = {}
  if (!(settingsString instanceof String) || settingsString == "")
    return loadedSlotPresets.set(res)

  try {
    res = parse_json(settingsString)
  }
  catch(e) {
    logerr($"Failed to load slot presets data")
  }
  loadedSlotPresets.set(res)
}

let playerSelectedPresetIdx = Watched(null)
let playerSelectedSlotIdx = Watched(null)

function clearActivePresetData() {
  playerSelectedPresetIdx.set(null)
  playerSelectedSlotIdx.set(null)
}

function saveSlotPresets(presetList, campaign) {
  loadedSlotPresets.mutate(@(v) v.$rawset(campaign, presetList))
  if (isOnlineSettingsAvailable.get()) {
    let blk = get_local_custom_settings_blk()
    blk[SAVE_ID] = presetList.len() == 0 ? "" : object_to_json_string(loadedSlotPresets.get())
    eventbus_send("saveProfile", {})
  }
  clearActivePresetData()
}

let savedSlotPresets = Computed(@() loadedSlotPresets.get()?[curCampaign.get()] ?? [])
let setSavedSlotPresets = @(presets, campaign) isEqual(presets, loadedSlotPresets.get()?[campaign] ?? []) ? null
  : saveSlotPresets(presets, campaign)

let currentPresetUnits = Computed(@() curSlots.get().map(@(s) s.name))

let currentPresetName = Watched("")

let isOpenedPresetWnd = mkWatched(persist, "OpenedPresetWnd" ,false)

return {
  isOpenedPresetWnd
  openSlotPresetWnd = @() isOpenedPresetWnd.set(true)
  closeSlotPresetWnd = function() {
    isOpenedPresetWnd.set(false)
    clearActivePresetData()
  }
  playerSelectedPresetIdx
  playerSelectedSlotIdx
  savedSlotPresets
  currentPresetUnits
  currentPresetName
  loadSlotPresets
  setSavedSlotPresets
}
