from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { object_to_json_string, parse_json } = require("json")
let { isEqual } = require("%sqstd/underscore.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")

let SAVE_ID = "slotSavedPresets"
let SLOT_PRESETS_VERSION_KEY = "slotPresetsVersion"
let ACTUAL_VERSION = 2
let loadedSlotPresets = mkWatched(persist, "loadedSlotPresets", {})

function removeNC() {
  let sBlk = get_local_custom_settings_blk()
  if ((sBlk?[SLOT_PRESETS_VERSION_KEY] ?? 0) == ACTUAL_VERSION)
    return

  sBlk[SLOT_PRESETS_VERSION_KEY] = ACTUAL_VERSION
  let slotBlk = sBlk?[SAVE_ID]
  if (type(slotBlk) != "string" || slotBlk == "")
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
  eventbus_send("saveProfile", {})
}

function loadSlotPresets() {
  removeNC()
  let blk = get_local_custom_settings_blk()
  let settingsString = blk?[SAVE_ID]
  local res = {}
  if (type(settingsString) != "string" || settingsString == "")
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
