from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { register_command } = require("console")
let { object_to_json_string, parse_json } = require("json")
let { get_local_custom_settings_blk } = require("blkGetters")
let { eventbus_send } = require("eventbus")
let { round } =  require("math")
let { get_time_msec } = require("dagor.time")
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
let hudTuningStateByUnitType = Computed(@() presetsSaved.value.map(
  function(p) {
    let { transforms = {}, resolution = [], options = {} } = p
    if (resolution?[1] == sh(100).tointeger() || (resolution?[1] ?? 0) <= 0)
      return { transforms, options }
    let mul = sh(100) / resolution[1]
    return {
      transforms = transforms.map(@(t) "pos" not in t ? t : t.__merge({ pos = t.pos.map(@(v) round(v * mul).tointeger()) }))
      options
    }
  }))
let tuningStateWithLastChange = mkWatched(persist, "tuningStateWithLastChange", null) //ts, changeUid, timeEnd
let tuningState = Computed(@() tuningStateWithLastChange.get()?.ts)
let tuningTransform = Computed(@() tuningState.get()?.transforms)
let tuningOptions = Computed(@() tuningState.get()?.options)
let selectedId = mkWatched(persist, "selectedId", null)
let isAllElemsOptionsOpened = mkWatched(persist, "isAllElemsOptionsOpened", false)
let transformInProgress = Watched(null)
let isElemHold = Watched(false)
let history = mkWatched(persist, "history", [])
let curHistoryIdx = Computed(@() history.get().findindex(@(h) h.ts == tuningState.get()))

let canShowRadar = mkWatched(persist, "canShowRadar", true)

let mkEmptyTuningState = @() { transforms = {}, options = {} }

selectedId.subscribe(@(v) v != null ? isAllElemsOptionsOpened.set(false) : null)
isAllElemsOptionsOpened.subscribe(@(v) v ? selectedId.set(null) : null)

let isCurPresetChanged = Computed(function() {
  let ut = tuningUnitType.value
  if (ut == null || tuningState.get() == null)
    return false
  return !isEqual(tuningState.get(), hudTuningStateByUnitType.get()?[ut] ?? mkEmptyTuningState())
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
  htBlk[unitType] = object_to_json_string(preset)
  presetsSaved.mutate(@(v) v[unitType] <- preset)
  eventbus_send("saveProfile", {})
}

local lastHistoryIdx = curHistoryIdx.value
tuningStateWithLastChange.subscribe(function(t) {
  if (t == null || curHistoryIdx.value != null) {
    lastHistoryIdx = curHistoryIdx.value
    return
  }
  local h = clone history.get()
  let lastHistory = h?[h.len() - 1]
  let isStackToLast = lastHistory != null
    && lastHistory.changeUid == t.changeUid
    && lastHistory.timeEnd >= get_time_msec()

  if (isStackToLast)
    h[h.len() - 1] = t
  else {
    if (lastHistoryIdx != null && lastHistoryIdx < h.len())
      h = h.slice(0, lastHistoryIdx + 1)
    h.append(t)
    if (h.len() > MAX_HISTORY_LEN)
      h.remove(0)
  }
  lastHistoryIdx = curHistoryIdx.get()
  history.set(h)
})

let setTuningState = @(ts, changeUid = "", changeStackTime = 0)
  tuningStateWithLastChange.set({ ts, changeUid, timeEnd = get_time_msec() + (1000 * changeStackTime).tointeger() })

function setByHistory(historyIdx) {
  let h = history.get()?[historyIdx]
  if (h != null)
    tuningStateWithLastChange.set(h)
}

tuningUnitType.subscribe(function(ut) {
  history.set([])
  setTuningState(ut == null ? null : freeze(hudTuningStateByUnitType.get()?[ut] ?? mkEmptyTuningState()))
})

let clearTuningState = @() setTuningState(mkEmptyTuningState())

let saveCurrentTransform = @() tuningUnitType.value == null ? null
  : savePreset(tuningUnitType.value,
      tuningState.get() == null ? {}
        : tuningState.get().__merge({ resolution = [sw(100).tointeger(), sh(100).tointeger()] }))

function applyTransformProgress() {
  if (selectedId.value == null || transformInProgress.value == null)
    return
  let state = tuningState.get()
  setTuningState(state.__merge({
    transforms = state.transforms.__merge({ [selectedId.value] = transformInProgress.get() })
  }))
  transformInProgress(null)
}

function openTuningRecommended() {
  let uType = isInBattle.value ? hudUnitType.value
    : hangarUnitName.value != "" ? getUnitType(hangarUnitName.value)
    : null
  tuningUnitType(uType in allTuningUnitTypes ? uType : allTuningUnitTypes.findindex(@(_) true))
}

let logSelElem = @(id) dlog("Hud tuning selectedId: ", id)  // warning disable: -forbidden-function
local isLogSelOn = false
register_command(function() {
  isLogSelOn = !isLogSelOn
  if (!isLogSelOn)
    selectedId.unsubscribe(logSelElem)
  else {
    selectedId.subscribe(logSelElem)
    logSelElem(selectedId.get())
  }
}, "hudTuning.debugElems")

return {
  allTuningUnitTypes
  hudTuningStateByUnitType
  isTuningOpened
  tuningUnitType
  tuningState
  tuningTransform
  tuningOptions
  setTuningState
  setByHistory
  transformInProgress
  isElemHold
  selectedId
  isAllElemsOptionsOpened
  history
  curHistoryIdx
  isCurPresetChanged
  canShowRadar

  openTuning = @(unitType) tuningUnitType(unitType)
  openTuningRecommended
  closeTuning = @() tuningUnitType(null)
  applyTransformProgress
  saveCurrentTransform
  clearTuningState
}