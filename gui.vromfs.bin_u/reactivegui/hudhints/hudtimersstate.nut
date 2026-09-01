from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "eventbus" import eventbus_subscribe
from "%sqstd/time.nut" import secondsToTimeSimpleString
from "%sqstd/underscore.nut" import isEqual
from "%globalScripts/timers.nut" import mkCountdownTimerSec
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/unitConst.nut" import SHIP, BOAT, SUBMARINE
from "%rGui/hud/crewState.nut" import crewState, crewDriverState, crewGunnerState, crewLoaderState
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
from "%rGui/hudHints/commonHintLogState.nut" import modifyOrAddEvent
from "%rGui/hudState.nut" import unitType


const REPAIR_SHOW_TIME_THRESHOLD = 0.5
const winkFast = 1.5

let activeTimers = mkWatched(persist, "activeTimers", {}) 
let timersVisibility = Computed(function(prev) {
  let res = activeTimers.get().map(@(_) true)
  return isEqual(prev, res) ? prev : res
})

let countdowns = {}
function getTimerCountdownSec(id) {
  if (id not in countdowns)
    countdowns[id] <- mkCountdownTimerSec(Computed(@() activeTimers.get()?[id].endTime ?? 0))
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

let clearTimers = @(_) activeTimers.set({})
let removeTimer = @(timerId) timerId not in activeTimers.get() ? null
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
subscribeHudEvent("TankDebuffs:Repair", onRepair)
subscribeHudEvent("ShipDebuffs:Repair", onRepair)

function repairMessage(val) {
  if (unitType.get() == SHIP || unitType.get() == BOAT || unitType.get() == SUBMARINE)
    return

  const msgId = "MSG_EVENT_HINT"
  modifyOrAddEvent({
    id = msgId
    hType = "simpleTextTiny"
    ttl = 1.0
    text = val > 0 ? " ".concat(loc("NUD_TIME_TO_TANK_REPAIR"), secondsToTimeSimpleString(val)) : ""
  },
  @(ev) ev?.id == msgId)
}
getTimerCountdownSec("repair_auto_status").subscribe(repairMessage)
getTimerCountdownSec("repair_status").subscribe(repairMessage)

subscribeHudEvent("ShipDebuffs:Extinguish", @(data) activeTimers.mutate(function onExtinguish(actTimers) {
  let { state, time = 0 } = data
  if (state == "notInExtinguish" || time <= 0)
    deleteF(actTimers, "extinguish_status")
  else
    actTimers.extinguish_status <- mkTimer(time, { needCountdown = true })
}))

subscribeHudEvent("ShipDebuffs:CancelExtinguish", @(data) onCancelAction("extinguish_status", data?.time ?? 0))

let onMoveCooldown = @(data) activeTimers.mutate(function onMoveCooldownImpl(actTimers) {
  let { time = 0 } = data
  if (time <= 0)
    deleteF(actTimers, "move_cooldown_status")
  else
    actTimers.move_cooldown_status <- mkTimer(time, { isForward = false })
})
eventbus_subscribe("TankDebuffs:MoveCooldown", onMoveCooldown)
subscribeHudEvent("ShipDebuffs:Cooldown", onMoveCooldown)

subscribeHudEvent("ShipDebuffs:RepairBreaches", @(data) activeTimers.mutate(function onRepairBreaches(actTimers) {
  let { state, time = 0 } = data
  if (time <= 0 || state == "notInRepair") {
    deleteF(actTimers, "unwatering_status")
    deleteF(actTimers, "repair_breaches_status")
    return
  }

  let timerId = state == "unwatering" ? "unwatering_status" : "repair_breaches_status"
  actTimers[timerId] <- mkTimer(time, { needCountdown = true })
}))

subscribeHudEvent("ShipDebuffs:CancelRepairBreaches", @(data) onCancelAction(
  "unwatering_status" in activeTimers.get() ? "unwatering_status" : "repair_breaches_status",
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
subscribeHudEvent("ShipDebuffs:Rearm", onRearm)

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

subscribeHudEvent("LocalPlayerDead", clearTimers)
subscribeHudEvent("MissionResult", clearTimers)
isInBattle.subscribe(@(_) clearTimers(null))

return {
  activeTimers
  timersVisibility
  removeTimer
  getTimerCountdownSec
}