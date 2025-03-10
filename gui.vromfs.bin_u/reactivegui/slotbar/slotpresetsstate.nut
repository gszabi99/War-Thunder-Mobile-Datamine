from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { object_to_json_string, parse_json } = require("json")
let { isEqual } = require("%sqstd/underscore.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { slots } = require("%rGui/slotBar/slotBarState.nut")

let SAVE_ID = "slotSavedPresets"
let loadedSlotPresets = Watched({})

function loadSlotPresets() {
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

let currentPresetUnits = Computed(@() slots.get().map(@(s) s.name))

let currentPresetName = Watched("")

let isOpenedPresetWnd = Watched(false)

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
