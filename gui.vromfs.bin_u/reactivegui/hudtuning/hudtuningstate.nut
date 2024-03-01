from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { register_command } = require("console")
let { json_to_string, parse_json } = require("json")
let { get_local_custom_settings_blk } = require("blkGetters")
let { eventbus_send } = require("eventbus")
let { round } =  require("math")
let { eachParam, isDataBlock } = require("%sqstd/datablock.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let hudUnitType = require("%rGui/hudState.nut").unitType

const SAVE_ID = "hudTuning"
const MAX_HISTORY_LEN = 200
let allTuningUnitTypes = [TANK, AIR, SHIP, SUBMARINE]
  .reduce(@(res, v) res.__update({ [v] = true }), {})

let tuningUnitType = mkWatched(persist, "tuningUnitType", null)
let isTuningOpened = Computed(@() tuningUnitType.value != null)
let presetsSaved = mkWatched(persist, "presetsSaved", {})
let transformsByUnitType = Computed(@() presetsSaved.value.map(
  function(p) {
    let { transforms = {}, resolution = [] } = p
    if (resolution?[1] == sh(100).tointeger() || (resolution?[1] ?? 0) <= 0)
      return transforms
    let mul = sh(100) / resolution[1]
    return transforms.map(@(t) "pos" not in t ? t : t.__merge({ pos = t.pos.map(@(v) round(v * mul).tointeger()) }))
  }))
let tuningTransform = mkWatched(persist, "tuningTransform", null)
let selectedId = mkWatched(persist, "selectedId", null)
let transformInProgress = Watched(null)
let history = mkWatched(persist, "history", [])
let curHistoryIdx = Computed(@() history.value.indexof(tuningTransform.value))

let isCurPresetChanged = Computed(function() {
  let ut = tuningUnitType.value
  if (ut == null || tuningTransform.value == null)
    return false
  return !isEqual(tuningTransform.value, transformsByUnitType.value?[ut] ?? {})
})

function loadPresets() {
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SAVE_ID]
  if (!isDataBlock(htBlk)) {
    presetsSaved({})
    return
  }
  let res = {}
  eachParam(htBlk, function(preset, unitType) {
    try {
      res[unitType] <- parse_json(preset)
    }
    catch(e) {
      logerr($"Failed to load hud tuning data for {unitType}")
    }
  })
  presetsSaved(res)
}

if (isOnlineSettingsAvailable.value && presetsSaved.value.len() == 0)
  loadPresets()
isOnlineSettingsAvailable.subscribe(@(_) loadPresets())

function savePreset(unitType, preset) {
  let blk = get_local_custom_settings_blk()
  let htBlk = blk.addBlock(SAVE_ID)
  htBlk[unitType] = json_to_string(preset)
  presetsSaved.mutate(@(v) v[unitType] <- preset)
  eventbus_send("saveProfile", {})
}

local lastHistoryIdx = curHistoryIdx.value
tuningTransform.subscribe(function(t) {
  if (t == null || curHistoryIdx.value != null) {
    lastHistoryIdx = curHistoryIdx.value
    return
  }
  local h = clone history.value
  if (lastHistoryIdx != null && lastHistoryIdx < h.len())
    h = h.slice(0, lastHistoryIdx + 1)
  h.append(t)
  if (h.len() > MAX_HISTORY_LEN)
    h.remove(0)
  lastHistoryIdx = curHistoryIdx.value
  history(h)
})

tuningUnitType.subscribe(function(ut) {
  history([])
  tuningTransform(ut == null ? null : freeze(transformsByUnitType.value?[ut] ?? {}))
})

let saveCurrentTransform = @() tuningUnitType.value == null ? null
  : savePreset(tuningUnitType.value,
      tuningTransform.value == null ? {}
        : {
            resolution = [sw(100).tointeger(), sh(100).tointeger()]
            transforms = tuningTransform.value
          })

function applyTransformProgress() {
  if (selectedId.value == null || transformInProgress.value == null)
    return
  tuningTransform(tuningTransform.value.__merge({
    [selectedId.value] = transformInProgress.value
  }))
  transformInProgress(null)
}

function openTuningRecommended() {
  let uType = isInBattle.value ? hudUnitType.value
    : hangarUnitName.value != "" ? getUnitType(hangarUnitName.value)
    : null
  tuningUnitType(uType in allTuningUnitTypes ? uType : allTuningUnitTypes.findindex(@(_) true))
}

register_command(@() tuningUnitType(tuningUnitType.value == TANK ? null : TANK), "openHudTuning.TANK")
register_command(@() tuningUnitType(tuningUnitType.value == AIR ? null : AIR), "openHudTuning.AIR")
register_command(@() tuningUnitType(tuningUnitType.value == SHIP ? null : SHIP), "openHudTuning.SHIP")
register_command(@() tuningUnitType(tuningUnitType.value == SUBMARINE ? null : SUBMARINE), "openHudTuning.SUBMARINE")
register_command(function() {
  tuningTransform({})
  saveCurrentTransform()
}, "resetHudTuning")

return {
  allTuningUnitTypes
  transformsByUnitType
  isTuningOpened
  tuningUnitType
  tuningTransform
  transformInProgress
  selectedId
  history
  curHistoryIdx
  isCurPresetChanged

  openTuning = @(unitType) tuningUnitType(unitType)
  openTuningRecommended
  closeTuning = @() tuningUnitType(null)
  applyTransformProgress
  saveCurrentTransform
}