from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { json_to_string, parse_json } = require("json")
let { isEqual } = require("%sqstd/underscore.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")

const SAVE_ID = "skinTuning"

let loadedTuning = Watched({})

function loadSkinTuning(unitName) {
  let blk = get_local_custom_settings_blk()
  let tuningString = blk?[SAVE_ID][unitName]
  if (type(tuningString) != "string" || tuningString == "")
    return {}

  local res = {}
  try {
    res = parse_json(tuningString)
  }
  catch(e) {
    logerr($"Failed to load skin tuning data")
  }
  return res
}

function saveSkinTuning(unitName, tuning) {
  let blk = get_local_custom_settings_blk()
  let allBlk = blk.addBlock(SAVE_ID)
  allBlk[unitName] = tuning.len() == 0 ? "" : json_to_string(tuning)
  eventbus_send("saveProfile", {})
}

let function loadTuningOnce(unitName) {
  if (loadedTuning.get()?[unitName] == null && (unitName ?? "") != "")
    loadedTuning.mutate(@(v) v.$rawset(unitName, loadSkinTuning(unitName)))
}

isOnlineSettingsAvailable.subscribe(function(s) {
  if (loadedTuning.get().len() == 0)
    return
  loadedTuning.set(loadedTuning.get().map(@(_, unitName) s ? loadSkinTuning(unitName) : null))
})

function mkSkinTuningWatch(unitNameW) {
  let skinTuning = Computed(@() loadedTuning.get()?[unitNameW.get()] ?? {})
  loadTuningOnce(unitNameW.get())
  skinTuning.subscribe(@(v) v.len() != 0 ? null : loadTuningOnce(unitNameW.get())) //subscribe not on unitNameW only to allow skinTuning correct remove from memore when unused
  function updateSkinTuning(ovr) {
    let unitName = unitNameW.get()
    let newValue = skinTuning.get().__merge(ovr)
    if (isOnlineSettingsAvailable.get())
      saveSkinTuning(unitName, newValue)
    loadedTuning.mutate(@(v) v.$rawset(unitName, newValue))
  }
  return { skinTuning, updateSkinTuning }
}

function mkIsAutoSkin(unitNameW) {
  let { skinTuning, updateSkinTuning } = mkSkinTuningWatch(unitNameW)
  let isAutoSkin = Computed(@() skinTuning.get()?.isAuto ?? false)
  let setAutoSkin = @(isAuto) isAuto == isAutoSkin.get() ? null
    : updateSkinTuning({ isAuto })
  return { isAutoSkin, setAutoSkin }
}

function isAutoSkin(unitName) {
  loadTuningOnce(unitName)
  return loadedTuning.get()?[unitName].isAuto ?? false
}

function mkSkinCustomTags(unitNameW) {
  let { skinTuning, updateSkinTuning } = mkSkinTuningWatch(unitNameW)
  let skinCustomTags = Computed(@() skinTuning.get()?.tags ?? {})
  let setSkinCustomTags = @(tags) isEqual(tags, skinCustomTags.get()) ? null
    : updateSkinTuning({ tags })
  return { skinCustomTags, setSkinCustomTags }
}

function getSkinCustomTags(unitName) {
  loadTuningOnce(unitName)
  return loadedTuning.get()?[unitName].tags ?? {}
}

return {
  mkSkinTuningWatch
  mkIsAutoSkin
  isAutoSkin
  mkSkinCustomTags
  getSkinCustomTags
}