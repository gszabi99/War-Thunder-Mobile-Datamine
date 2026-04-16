from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import round_by_value
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
from "hudTuningConsts.nut" import tuningStateDefault, ALIGN_C, ALIGN_L, ALIGN_R, ALIGN_T, ALIGN_B
from "hudTuningState.nut" import tuningStateOnOpen, tuningUnitType, hudTuningStateByUnitType, optionsToElemIds,
  mkEmptyTuningState, registerBeforeUnitTypeChangeCb
from "cfgByUnitType.nut" import cfgByUnitType


let alignToString = {
  [ALIGN_R | ALIGN_T] = "RT",
  [ALIGN_R | ALIGN_B] = "RB",
  [ALIGN_R | ALIGN_C] = "RC",
  [ALIGN_L | ALIGN_T] = "LT",
  [ALIGN_L | ALIGN_B] = "LB",
  [ALIGN_L | ALIGN_C] = "LC",
  [ALIGN_C | ALIGN_T] = "CT",
  [ALIGN_C | ALIGN_B] = "CB",
  [ALIGN_C] = "CC",
}

function fillChangedElems(elemIds, s1, s2, uType) {
  foreach (id, v in s1?.options ?? {})
    if (id in tuningStateDefault.customOptions) {
      if (v != (s2?.options[id] ?? tuningStateDefault.customOptions[id]))
        elemIds[optionsToElemIds.get()[id]] <- true
    }
    else if (id in tuningStateDefault.options) {
      foreach (elemId, elemV in v)
        if (elemV != (s2?.options[id][elemId] ?? tuningStateDefault.options[id]))
          elemIds[elemId] <- true
    }
    else
      logerr($"Not found hud tuning option {id} in default config")

  foreach (id, v in s1?.transforms ?? {})
    if (!isEqual(v, s2?.transforms[id] ?? cfgByUnitType[uType][id].defTransform))
      elemIds[id] <- true
}

let getParam = @(value, idx) type(value) == "integer" ? $"paramInt{idx}"
  : type(value) == "float" ? $"paramFloat{idx}"
  : type(value) == "string" ? $"paramStr{idx}"
  : ""

function trySendToBq() {
  let uType = tuningUnitType.get()
  if (uType == null)
    return

  let prevState = tuningStateOnOpen.get()
  let newState = hudTuningStateByUnitType.get()?[uType] ?? mkEmptyTuningState()
  let changedElemIds = {}
  fillChangedElems(changedElemIds, prevState, newState, uType)
  fillChangedElems(changedElemIds, newState, prevState, uType)
  if (changedElemIds.len() == 0)
    return

  foreach (elemId, _ in changedElemIds) {
    let { options = [], isVisibleInEditor = Watched(true), defTransform } = cfgByUnitType[uType][elemId]
    if (!isVisibleInEditor.get())
      continue

    local idx = 0
    let { pos, align } = newState?.transforms[elemId] ?? defTransform

    let width = sw(100).tointeger()
    let height = sh(100).tointeger()
    let baseData = {
      elemId,
      posX = round_by_value(pos[0].tofloat() / width, 0.01),
      posY = round_by_value(pos[1].tofloat() / height, 0.01),
      align = alignToString?[align] ?? "?"
      scale = newState?.options.scale[elemId].tofloat() ?? tuningStateDefault.options.scale,
      resolution = $"{width} x {height}",
      unitType = uType
    }
    foreach (o in options) {
      if (o?.id == null || o.id == "scale")
        continue

      if (o.id in tuningStateDefault.options) {
        let rawVal = newState?.options[o.id][elemId] ?? tuningStateDefault.options[o.id]
        let val = type(rawVal) == "bool" ? rawVal.tointeger() : rawVal
        idx++
        baseData.__update({
          [getParam(val, idx)] = val,
          [$"paramId{idx}"] = o.id
        })
      }
      else if (o.id in tuningStateDefault.customOptions) {
        let rawVal = newState?.options[o.id] ?? tuningStateDefault.customOptions[o.id]
        let val = type(rawVal) == "bool" ? rawVal.tointeger() : rawVal
        idx++
        baseData.__update({
          [getParam(val, idx)] = val,
          [$"paramId{idx}"] = o.id
        })
      }
    }

    sendCustomBqEvent("hud_change_1", baseData)
  }
}

registerBeforeUnitTypeChangeCb(trySendToBq)
