from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { isInFlight } = require("%rGui/globalState.nut")
let { removeHudElementPointer } = require("%rGui/tutorial/hudElementPointers.nut")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { register_command } = require("console")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")
let { get_time_msec } = require("dagor.time")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

enum CFG_TYPES {
  MISSION_START
  CAPTURE_POINT
}

let seriesCfg = [
  [
    { hintId = "mission_goal", elementId = "mission_objective", duration = 5 }
    { hintId = "this_is_minimap", elementId = "tactical_map", duration = 5 }
    { hintId = "this_is_capture_point", elementId = ["capture_zone_indicator_0",
                                                     "capture_zone_indicator_1",
                                                     "capture_zone_indicator_2"], duration = 5 }
  ],
  [
    { hintId = "you_are_capturing", elementId = "mission_hint", duration = 5 }
    { hintId = "capture_zones", elementId = "capture_zones", duration = 5 }
    { hintId = "this_is_score_board", elementId = "score_board", duration = 5 }
    { hintId = "ticket_loose", elementId = "score_board", duration = 5 }
  ]
]

let areStartMissionHintsReady = mkWatched(persist, "areStartMissionHintsReady", false)
let areCaptureHintsReady = mkWatched(persist, "areCaptureHintsReady", false)

isInFlight.subscribe(function(v) {
  if (v) {
    areStartMissionHintsReady(true)
    areCaptureHintsReady(true)
  }
})

let seriaState = mkWatched(persist, "currentHintStage", { idx = -1 , cfgId = -1, nextStageTime = 0} )

let nextStageTimeSec = keepref(Computed(@() !isHudAttached.value || seriaState.value.cfgId not in seriesCfg
  ? 0
  : seriaState.value.nextStageTime))

let clearHintStage = @() seriaState({cfgId = -1, idx = -1, nextStageTime = 0})

isInBattle.subscribe(@(_) clearHintStage())

function nextStage() {
  local { idx, cfgId } = seriaState.value
  let cfg = seriesCfg?[cfgId]
  if (cfg == null)
    return
  let prevElementId = cfg?[idx].elementId
  if (prevElementId != null)
    removeHudElementPointer(prevElementId)

  idx++
  let hintCfg = cfg?[idx]
  if (hintCfg == null) {
    clearHintStage()
    return
  }
  let {hintId, elementId , duration = 0. } = hintCfg
  eventbus_send($"hint:{hintId}", { elementId , duration })
  seriaState.mutate(@(v) v.__update({ idx, nextStageTime = duration + get_time_msec() * 0.001}))
}

nextStageTimeSec.subscribe(@(time) time <= 0
  ? clearTimer(nextStage)
  : resetTimeout(max(0.01, time - get_time_msec() * 0.001), nextStage))

function addHintSeria(seriaCfgId) {
  seriaState.mutate(@(v) v.__update({cfgId = seriaCfgId, idx = -1}))
  nextStage()
}

let startMissionHintSeria =  function (){
  if (!areStartMissionHintsReady.value)
    return
  addHintSeria(CFG_TYPES.MISSION_START)
  areStartMissionHintsReady(false)
}
let captureHintSeria = function() {
  if (!areCaptureHintsReady.value)
    return
  addHintSeria(CFG_TYPES.CAPTURE_POINT)
  areCaptureHintsReady(false)
}

register_command(function() {
  areStartMissionHintsReady(true)
  startMissionHintSeria()
} , "start_mission_hint_seria")
register_command(function() {
  areCaptureHintsReady(true)
  captureHintSeria()
}, "capture_hint_seria")

return {
  startMissionHintSeria
  captureHintSeria
}