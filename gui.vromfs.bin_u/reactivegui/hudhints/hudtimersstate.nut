from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { isEqual } = require("%sqstd/underscore.nut")
let { crewState, crewDriverState, crewGunnerState, crewLoaderState } = require("%rGui/hud/crewState.nut")
let { mkCountdownTimerSec } = require("%globalScripts/timers.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let REPAIR_SHOW_TIME_THRESHOLD = 0.5
let winkFast = 1.5

let activeTimers = mkWatched(persist, "activeTimers", {}) //startTime, endTime, needCountdown, isForward, winkPeriod, text
let timersVisibility = Computed(function(prev) {
  let res = activeTimers.value.map(@(_) true)
  return isEqual(prev, res) ? prev : res
})

let countdowns = {}
function getTimerCountdownSec(id) {
  if (id not in countdowns)
    countdowns[id] <- mkCountdownTimerSec(Computed(@() activeTimers.value?[id].endTime ?? 0))
  return countdowns[id]
}

let deleteF = @(tbl, field) tbl?.$rawdelete(field)
let mkTimer = @(time, ovr = {}) {
  startTime = get_time_msec()
  endTime = get_time_msec() + (1000 * time).tointeger()
}.__update(ovr)

let mkTimerOffset = @(totalTime, currentTime, ovr = {}) {
  startTime = get_time_msec() - (1000 * currentTime).tointeger()
  endTime = get_time_msec() + (1000 * (totalTime - currentTime)).tointeger()
}.__update(ovr)

let clearTimers = @(_) activeTimers({})
let removeTimer = @(timerId) timerId not in activeTimers.value ? null
  : activeTimers.mutate(@(t) t.$rawdelete(timerId))

let onCancelAction = @(timerId, time) activeTimers.mutate(function onCancelActionImpl(actTimers) {
  if (time <= 0)
    deleteF(actTimers, timerId)
  else
    actTimers[timerId] <- mkTimer({ isForward = false })
})

let onRepair = @(data) activeTimers.mutate(function onRepairImpl(actTimers) {
  deleteF(actTimers, "repair_status")
  deleteF(actTimers, "repair_auto_status")

  let { state, time = 0, totalTime = 0 } = data
  let isPrepare = state == "prepareRepair"
  if (time <= 0
      || (time <= REPAIR_SHOW_TIME_THRESHOLD && !isPrepare)
      || state == "notInRepair")
    return

  let timerId = state == "repairingAuto" ? "repair_auto_status" : "repair_status"
  actTimers[timerId] <- mkTimerOffset(totalTime, totalTime - time, {
    needCountdown = !isPrepare
    isForward = !isPrepare
    winkPeriod = isPrepare ? winkFast : 0
  })
})
eventbus_subscribe("TankDebuffs:Repair", onRepair)
eventbus_subscribe("ShipDebuffs:Repair", onRepair)

eventbus_subscribe("ShipDebuffs:Extinguish", @(data) activeTimers.mutate(function onExtinguish(actTimers) {
  let { state, time = 0 } = data
  if (state == "notInExtinguish" || time <= 0)
    deleteF(actTimers, "extinguish_status")
  else
    actTimers.extinguish_status <- mkTimer(time, { needCountdown = true })
}))

eventbus_subscribe("ShipDebuffs:CancelExtinguish", @(data) onCancelAction("extinguish_status", data?.time ?? 0))

let onMoveCooldown = @(data) activeTimers.mutate(function onMoveCooldownImpl(actTimers) {
  let { time = 0 } = data
  if (time <= 0)
    deleteF(actTimers, "move_cooldown_status")
  else
    actTimers.move_cooldown_status <- mkTimer(time, { isForward = false })
})
eventbus_subscribe("TankDebuffs:MoveCooldown", onMoveCooldown)
eventbus_subscribe("ShipDebuffs:Cooldown", onMoveCooldown)

eventbus_subscribe("ShipDebuffs:RepairBreaches", @(data) activeTimers.mutate(function onRepairBreaches(actTimers) {
  let { state, time = 0 } = data
  if (time <= 0 || state == "notInRepair") {
    deleteF(actTimers, "unwatering_status")
    deleteF(actTimers, "repair_breaches_status")
    return
  }

  let timerId = state == "unwatering" ? "unwatering_status" : "repair_breaches_status"
  actTimers[timerId] <- mkTimer(time, { needCountdown = true })
}))

eventbus_subscribe("ShipDebuffs:CancelRepairBreaches", @(data) onCancelAction(
  "unwatering_status" in activeTimers.value ? "unwatering_status" : "repair_breaches_status",
  data?.time ?? 0))

let onRearm = @(data) activeTimers.mutate(function onRearmImpl(actTimers) {
  let { object_name, state, timeToLoadOne = 0, currentLoadTime = 0, rearmState = ""} = data
  if (timeToLoadOne <= 0 || state == "notInRearm")
    deleteF(actTimers, object_name)
  else {
    let isForward = (rearmState != "discharge")
    let curTime = isForward ? currentLoadTime : timeToLoadOne - currentLoadTime
    actTimers[object_name] <- mkTimerOffset(timeToLoadOne, curTime, { isPaused = (rearmState == "pause") , isForward })
  }
})
eventbus_subscribe("TankDebuffs:Rearm", onRearm)
eventbus_subscribe("ShipDebuffs:Rearm", onRearm)

eventbus_subscribe("TankDebuffs:Replenish", @(data) activeTimers.mutate(function onReplenish(actTimers) {
  let { isReplenishActive = false, periodTime = 0, currentLoadTime = 0 } = data
  if (!isReplenishActive || periodTime <= 0)
    deleteF(actTimers, "replenish_status")
  else
    actTimers.replenish_status <- mkTimerOffset(periodTime, currentLoadTime, { isForward = false })
}))

eventbus_subscribe("TankDebuffs:Battery", @(data) activeTimers.mutate(function onBattery(actTimers) {
  let { charge } = data
  if (charge >= 100)
    deleteF(actTimers, "battery_status")
  else
    actTimers.battery_status <- { text = charge.tointeger() }
}))
/*
eventbus_subscribe("TankDebuffs:Building", @(data) activeTimers.mutate(function onBuilding(actTimers) {
  let { timer = 0.0, inProgress = false } = data
  if (inProgress)
    deleteF(actTimers, "building_status")
  else
    actTimers.building_status <- { text = timer.tointeger() }
}))
*/
crewState.subscribe(@(data) activeTimers.mutate(function onCrewState(actTimers) {
  let { healing, totalHealingTime = 0, currentHealingTime = 0 } = data
  if (!healing || totalHealingTime <= 0)
    deleteF(actTimers, "healing_status")
  else
    actTimers.healing_status <- mkTimerOffset(totalHealingTime, currentHealingTime)
}))

let onCrewMemberState = @(timerId, data) activeTimers.mutate(function onCrewMemberStateImpl(actTimers) {
  let { state, totalTakePlaceTime = 0, timeToTakePlace = 0 } = data
  if (state != "takingPlace" || totalTakePlaceTime <= 0)
    deleteF(actTimers, timerId)
  else
    actTimers[timerId] <- mkTimerOffset(totalTakePlaceTime, totalTakePlaceTime - timeToTakePlace)
})
crewDriverState.subscribe(@(data) onCrewMemberState("driver_status", data))
crewGunnerState.subscribe(@(data) onCrewMemberState("gunner_status", data))
crewLoaderState.subscribe(@(data) onCrewMemberState("loader_status", data))

eventbus_subscribe("LocalPlayerDead", clearTimers)
eventbus_subscribe("MissionResult", clearTimers)
isInBattle.subscribe(@(_) clearTimers(null))

return {
  activeTimers
  timersVisibility
  removeTimer
  getTimerCountdownSec
}