from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { HIT_CAMERA_FINISH, HIT_CAMERA_START, HIT_CAMERA_FADE_IN, DM_HIT_RESULT_NONE, DM_HIT_RESULT_HIT, DM_HIT_RESULT_KILL
} = require("hitCamera")
let { subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { setTimeout, clearTimer, resetTimeout } = require("dagor.workcycle")
let cameraEventUnitType = require("cameraEventUnitType.nut")
let { hitResultCfg, defPartPriority, partsPriority } = require("hitCameraConfig.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { register_command } = require("console")

const MIN_SHOW_IMPORTANT_MSEC = 3000
const MAX_SHOW_HIT_MSEC = 6000

let defaultState = { mode = HIT_CAMERA_FINISH, result = DM_HIT_RESULT_NONE, info = {} }
let state = mkWatched(persist, "state", defaultState)
let unitsInfo = mkWatched(persist, "unitsInfo", {})
let hcDamageStatus = mkWatched(persist, "hcDamageStatus", {})
let hcImportantEvents = mkWatched(persist, "hcImportantEvents", [])
let curImportantResult = mkWatched(persist, "curImportantResult", null)
let hcResultByState = mkWatched(persist, "hcResultByState", null)
let mode = Computed(@() state.value.mode)
let hcInfo = Computed(@() state.value.info)
let isHcRender = Computed(@() mode.value != HIT_CAMERA_FINISH)
let shouldShowHc = Computed(@() mode.value == HIT_CAMERA_FADE_IN || mode.value == HIT_CAMERA_START)
let hcFadeTime = Computed(@(prev) state.value.info?.stopFadeTime
  ?? (prev == FRP_INITIAL ? 0.3 : prev))

let hcUnitId = Computed(@() state.value.info?.unitId)
let hcUnitType = Computed(@(prev) cameraEventUnitType?[state.value.info?.unitType]
  ?? (prev == FRP_INITIAL ? TANK : prev))
let hcUnitVersion = Computed(@(prev) state.value.info?.unitVersion ?? (prev == FRP_INITIAL ? -1 : prev))
let hcRelativeHealth = Computed(@() min(hcDamageStatus.value?.curRelativeHealth ?? 1.0, state.value.info?.curRelativeHealth ?? 1.0))

let validateByVersion = @(data, unitId, version) data == null ? data
  : data.unitId == unitId && data.unitVersion == version ? data
  : null

let hcResult = Computed(function() {
  let sResult = validateByVersion(hcResultByState.value, hcUnitId.value, hcUnitVersion.value)
  let iResult = validateByVersion(curImportantResult.value, hcUnitId.value, hcUnitVersion.value)
  if (sResult == null || iResult == null)
    return sResult ?? iResult
  return iResult.isRelevant || iResult.time > sResult.time ? iResult : sResult
})

isInBattle.subscribe(function(_) {
  state(defaultState)
  unitsInfo({})
})
hcUnitVersion.subscribe(@(_) hcDamageStatus({}))
hcUnitId.subscribe(@(_) hcDamageStatus({}))

let mkDefaultUnitInfo = @(unitVersion) {
  unitVersion
  parts = {}
  isKilled = false //by dmg parts event
}
let emptyUnitInfo = mkDefaultUnitInfo(-1)

let hcUnitDmgPartsUnitInfo = Computed(function() {
  let res = unitsInfo.value?[hcUnitId.value]
  return (res == null || res.unitVersion != hcUnitVersion.value) ? emptyUnitInfo : res
})
let isHcUnitHit = Computed(@() state.value.result >= DM_HIT_RESULT_HIT || hcUnitDmgPartsUnitInfo.value.isKilled)
let isHcUnitKilled = Computed(@() state.value.result >= DM_HIT_RESULT_KILL || hcUnitDmgPartsUnitInfo.value.isKilled)
let hcDmgPartsInfo = Computed(@() hcUnitDmgPartsUnitInfo.value.parts)

let modifyUnitInfo = @(unitId, unitVersion, update)
  unitsInfo.mutate(function(list) {
    local info = list?[unitId]
    if (info?.unitVersion == unitVersion)
      info = clone info
    else
      info = mkDefaultUnitInfo(unitVersion)
    update(info)
    list[unitId] <- info
  })

isHcRender.subscribe(@(v) v ? null : unitsInfo.mutate(function(list) {
  foreach (unitId, unitInfo in list) {
    local hasUnitChanges = false
    foreach (partName, part in unitInfo.parts) {
      local hasPartChanges = false
      foreach (partDmName, dmPart in part) {
        if (dmPart?.partKilled == true) {
          hasUnitChanges = true
          hasPartChanges = true
          part[partDmName] = dmPart.__merge({ partKilled = false })
        }
      }
      if (hasPartChanges)
        unitInfo.parts[partName] = clone part
    }
    if (hasUnitChanges)
      list[unitId] = clone unitInfo
  }
}))

let function onEnemyPartDamage(data) {
  let { unitId = -1, unitVersion = -1, unitKilled = false, partName = null, partDmName = null
  } = data
  modifyUnitInfo(unitId, unitVersion,
    function updateOnPartDamage(unitInfo) {
      unitInfo.isKilled = unitInfo.isKilled || unitKilled
      if (unitInfo.isKilled || partName == null)
        return

      let parts = clone unitInfo.parts
      unitInfo.parts = parts

      parts[partName] <- partName in parts ? clone parts[partName] : {}
      let prevPartKilled = parts[partName]?[partDmName].partKilled ?? false
      let dmPart = (parts[partName]?[partDmName] ?? {}).__merge(data)
      if (prevPartKilled)
        dmPart.partKilled <- true
      if (partDmName != null)
        parts[partName][partDmName] <- dmPart
    })
}


let clearHcResultByState = @() hcResultByState(null)

state.subscribe(function(s) {
  let { result } = s
  let cfg = hitResultCfg?[result]
  if (cfg == null)
    return
  hcResultByState(cfg.__merge({
    unitId = hcUnitId.value
    unitVersion = hcUnitVersion.value
    time = get_time_msec()
  }))
  resetTimeout(0.001 * MAX_SHOW_HIT_MSEC, clearHcResultByState)
})

if (hcResultByState.value != null) {
  let timeLeft = hcResultByState.value.time + MAX_SHOW_HIT_MSEC - get_time_msec()
  if (timeLeft > 0)
    setTimeout(0.001 * timeLeft, clearHcResultByState)
  else
    clearHcResultByState()
}


let function getImportantEventInfo(event) {
  local priority = -1
  local result = null
  let { unitId, unitVersion, partEvent } = event
  let parts = type(partEvent) == "array" ? partEvent : [partEvent] //base event data is datablock, so type of this field is not fixed
  foreach (part in parts) {
    let { partName = null } = part
    if (partName == null)
      continue
    let partPriority = partsPriority?[partName] ?? defPartPriority
    if (partPriority <= priority)
      continue
    priority = partPriority
    result = {
      styleId = "kill",
      locId = $"part_destroyed/{partName}"
    }
  }

  if (result != null) {
    if (unitId == hcUnitId.value && unitVersion == hcUnitVersion.value)
      priority += 10000000
    result.__update({ unitId, unitVersion })
  }
  return { priority, result }
}

let function updateCurImportantResult() {
  if (hcImportantEvents.value.len() == 0) {
    let { time } = curImportantResult.value
    let timeLeft = time + MAX_SHOW_HIT_MSEC - get_time_msec()
    if (timeLeft <= 0)
      curImportantResult(null)
    else {
      curImportantResult.mutate(@(r) r.isRelevant = false)
      setTimeout(0.001 * timeLeft, updateCurImportantResult)
    }
    return
  }

  local found = null
  foreach (ev in hcImportantEvents.value) {
    let info = getImportantEventInfo(ev)
    if (info.priority >= (found?.priority ?? -1))
      found = info
  }
  hcImportantEvents([])
  let { result } = found
  if (result != null) {
    result.__update({ time = get_time_msec(), isRelevant = true })
    setTimeout(0.001 * MIN_SHOW_IMPORTANT_MSEC, updateCurImportantResult)
  }
  curImportantResult(result)
}

if (curImportantResult.value != null) {
  let timeLeft = curImportantResult.value.time + MAX_SHOW_HIT_MSEC - get_time_msec()
  if (timeLeft > 0)
    setTimeout(0.001 * timeLeft, updateCurImportantResult)
  else
    updateCurImportantResult()
}

let function updateCurImportantResultOnUnitChange() {
  let id = hcUnitId.value
  let version = hcUnitVersion.value
  if (null != hcImportantEvents.value.findvalue(@(ev) ev.unitId == id && ev.unitVersion == version)) {
    clearTimer(updateCurImportantResult)
    updateCurImportantResult()
  }
}
hcUnitId.subscribe(@(_) updateCurImportantResultOnUnitChange())
hcUnitVersion.subscribe(@(_) updateCurImportantResultOnUnitChange())

let function onHitCameraImportantEvents(data) {
  let { unitId, unitVersion, partEvent = null } = data
  if (partEvent == null || !isHcRender.value
      || unitId != hcUnitId.value || unitVersion != hcUnitVersion.value)
    return
  hcImportantEvents.mutate(@(curEvents) curEvents.append(data))
  if (curImportantResult.value == null
      || curImportantResult.value.time + MIN_SHOW_IMPORTANT_MSEC < get_time_msec()) {
    clearTimer(updateCurImportantResult)
    updateCurImportantResult()
  }
}

subscribe("hitCamera", @(ev) state(ev))
subscribe("EnemyPartDamage", onEnemyPartDamage)
subscribe("EnemyDamageState", @(ev) ev.unitId != hcUnitId.value ? null
  : hcDamageStatus(ev.updateDebuffsOnly ? hcDamageStatus.value.__merge(ev) : ev))
subscribe("HitCameraImportanEvents", onHitCameraImportantEvents)


let partsBrokenInfo = @(unitInfo) unitInfo.parts.map(@(dmList)
  dmList.map(@(dm) (dm?.partKilled ?? false) || (dm?.partDead ?? false) || (dm?.partHp ?? 1.0) <= 0))

register_command(
  @() log("curDmgPartsInfo:", hcUnitDmgPartsUnitInfo.value)
  "hitcamera.debugCurDmgPartsInfo")
register_command(
  @() log("allDmgPartsInfo:", unitsInfo.value)
  "hitcamera.debugAllDmgPartsInfo")
register_command(
  @() log("curDmgPartsInfo:", partsBrokenInfo(hcUnitDmgPartsUnitInfo.value))
  "hitcamera.debugCurDmgPartsBroken")
register_command(
  @() log("allDmgPartsInfo:", unitsInfo.value.map(partsBrokenInfo))
  "hitcamera.debugAllDmgPartsBroken")

return {
  isHcRender
  shouldShowHc
  hcFadeTime
  hcResult
  hcUnitType
  hcInfo
  hcDamageStatus
  hcDmgPartsInfo
  hcRelativeHealth
  isHcUnitHit
  isHcUnitKilled
}