from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { isEqual } = require("%sqstd/underscore.nut")
let { crewState, crewDriverState, crewGunnerState, crewLoaderState } = require("%rGui/hud/crewState.nut")

let REPAIR_SHOW_TIME_THRESHOLD = 0.5
let winkFast = 1.5

let activeTimers = mkWatched(persist, "activeTimers", {}) //startTime, endTime, needCountdown, isForward, winkPeriod, text
let timersVisibility = Computed(function(prev) {
  let res = activeTimers.value.map(@(_) true)
  return isEqual(prev, res) ? prev : res
})

let deleteF = @(tbl, field) field in tbl ? delete tbl[field] : null
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
  : activeTimers.mutate(@(t) delete t[timerId])

let onCancelAction = @(timerId, time) activeTimers.mutate(function onCancelActionImpl(actTimers) {
  if (time <= 0)
    deleteF(actTimers, timerId)
  else
    actTimers[timerId] <- mkTimer({ isForward = false })
})

let onRepair = @(data) activeTimers.mutate(function onRepairImpl(actTimers) {
  deleteF(actTimers, "repair_status")
  deleteF(actTimers, "repair_auto_status")

  let { state, time = 0 } = data
  let isPrepare = state == "prepareRepair"
  if (time <= 0
      || (time <= REPAIR_SHOW_TIME_THRESHOLD && !isPrepare)
      || state == "notInRepair")
    return

  let timerId = state == "repairingAuto" ? "repair_auto_status" : "repair_status"
  actTimers[timerId] <- mkTimer(time, {
    needCountdown = !isPrepare
    isForward = !isPrepare
    winkPeriod = isPrepare ? winkFast : 0
  })
})
subscribe("TankDebuffs:Repair", onRepair)
subscribe("ShipDebuffs:Repair", onRepair)

subscribe("ShipDebuffs:Extinguish", @(data) activeTimers.mutate(function onExtinguish(actTimers) {
  let { state, time = 0 } = data
  if (state == "notInExtinguish" || time <= 0)
    deleteF(actTimers, "extinguish_status")
  else
    actTimers.extinguish_status <- mkTimer(time, { needCountdown = true })
}))

subscribe("ShipDebuffs:CancelExtinguish", @(data) onCancelAction("extinguish_status", data?.time ?? 0))

let onMoveCooldown = @(data) activeTimers.mutate(function onMoveCooldownImpl(actTimers) {
  let { time = 0 } = data
  if (time <= 0)
    deleteF(actTimers, "move_cooldown_status")
  else
    actTimers.move_cooldown_status <- mkTimer(time, { isForward = false })
})
subscribe("TankDebuffs:MoveCooldown", onMoveCooldown)
subscribe("ShipDebuffs:Cooldown", onMoveCooldown)

subscribe("ShipDebuffs:RepairBreaches", @(data) activeTimers.mutate(function onRepairBreaches(actTimers) {
  let { state, time = 0 } = data
  if (time <= 0 || state == "notInRepair") {
    deleteF(actTimers, "unwatering_status")
    deleteF(actTimers, "repair_breaches_status")
    return
  }

  let timerId = state == "unwatering" ? "unwatering_status" : "repair_breaches_status"
  actTimers[timerId] <- mkTimer(time, { needCountdown = true })
}))

subscribe("ShipDebuffs:CancelRepairBreaches", @(data) onCancelAction(
  "unwatering_status" in activeTimers.value ? "unwatering_status" : "repair_breaches_status",
  data?.time ?? 0))

let onRearm = @(data) activeTimers.mutate(function onRearmImpl(actTimers) {
  let { object_name, state, timeToLoadOne = 0, currentLoadTime = 0 } = data
  if (timeToLoadOne <= 0 || state == "notInRearm")
    deleteF(actTimers, object_name)
  else
    actTimers[object_name] <- mkTimerOffset(timeToLoadOne, currentLoadTime)
})
subscribe("TankDebuffs:Rearm", onRearm)
subscribe("ShipDebuffs:Rearm", onRearm)

subscribe("TankDebuffs:Replenish", @(data) activeTimers.mutate(function onReplenish(actTimers) {
  let { isReplenishActive = false, periodTime = 0, currentLoadTime = 0 } = data
  if (!isReplenishActive || periodTime <= 0)
    deleteF(actTimers, "replenish_status")
  else
    actTimers.replenish_status <- mkTimerOffset(periodTime, currentLoadTime, { isForward = false })
}))

subscribe("TankDebuffs:Battery", @(data) activeTimers.mutate(function onBattery(actTimers) {
  let { charge } = data
  if (charge >= 100)
    deleteF(actTimers, "battery_status")
  else
    actTimers.battery_status <- { text = charge.tointeger() }
}))

crewState.subscribe(@(data) activeTimers.mutate(function onCrewState(actTimers) {
  let { healing, totalHealingTime = 0, currentHealingTime = 0 } = data
  if (!healing || totalHealingTime <= 0)
    deleteF(actTimers, "healing_status")
  else
    actTimers.healing_status <- mkTimerOffset(totalHealingTime, currentHealingTime)
}))

let onCrewMemberState = @(timerId, data) activeTimers.mutate(function onCrewMemberState(actTimers) {
  let { state, totalTakePlaceTime = 0, timeToTakePlace = 0 } = data
  if (state != "takingPlace" || totalTakePlaceTime <= 0)
    deleteF(actTimers, timerId)
  else
    actTimers[timerId] <- mkTimerOffset(totalTakePlaceTime, totalTakePlaceTime - timeToTakePlace)
})
crewDriverState.subscribe(@(data) onCrewMemberState("driver_status", data))
crewGunnerState.subscribe(@(data) onCrewMemberState("gunner_status", data))
crewLoaderState.subscribe(@(data) onCrewMemberState("loader_status", data))

subscribe("LocalPlayerDead", clearTimers)
subscribe("MissionResult", clearTimers)

return {
  activeTimers
  timersVisibility
  removeTimer
}