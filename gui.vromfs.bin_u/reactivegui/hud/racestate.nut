from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import setInterval, clearTimer
from "eventbus" import eventbus_subscribe
from "mission" import get_mission_time
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
from "%rGui/missionState.nut" import isGtRace


let playerOrder = ["leader", "beforePlayer", "player", "afterPlayer"]
let raceData = mkWatched(persist, "raceData", null)
let raceStartTime = mkWatched(persist, "raceStartTime", null)
let raceTime = mkWatched(persist, "raceTime", -1)
let hasRaceState = Computed(@() raceData.get() != null)
let raceLeadershipPlayers = Computed(function(prev) {
  let res = []
  let { totalLaps = 0, checkpointsPerLap = 0 } = raceData.get()
  let total = totalLaps * checkpointsPerLap
  foreach (id in playerOrder) {
    let p = raceData.get()?[id]
    if (p == null)
      continue
    let { raceLap, raceLastCheckpoint } = p
    let progress = total <= 0 ? -1
      : (100 * (max(0, raceLap - 1) * checkpointsPerLap + raceLastCheckpoint) / total).tointeger()
    res.append(prevIfEqual(prev?[res.len()], p.__merge({ progress })))
  }
  return res
})
let raceCurrentLap = Computed(@() raceData.get()?.currentLap ?? 0)
let raceTotalLaps = Computed(@() raceData.get()?.totalLaps ?? 0)
let raceCurrentCheckpoint = Computed(@() raceData.get()?.passedCheckpointsInLap ?? 0)
let raceTotalCheckpoints = Computed(@() raceData.get()?.checkpointsPerLap ?? 0)

subscribeHudEvent("RaceSegmentUpdate", @(data) !isGtRace.get() ? null : raceData.set(data))
eventbus_subscribe("RaceStart", @(data) raceStartTime.set(data.start))
isInBattle.subscribe(function(v) {
  raceStartTime.set(null)
  if (v)
    raceData.set(null)
})

let updateRaceTime = @() raceTime.set(raceStartTime.get() == null ? -1
  : max(0, (get_mission_time() - raceStartTime.get() + 0.5).tointeger()))

function updateRaceTimer() {
  updateRaceTime()
  clearTimer(updateRaceTime)
  if (raceStartTime.get() != null)
    setInterval(1.0, updateRaceTime)
}
updateRaceTimer()
raceStartTime.subscribe(@(_) updateRaceTimer())

return {
  raceLeadershipPlayers
  raceCurrentLap
  raceTotalLaps
  raceCurrentCheckpoint
  raceTotalCheckpoints
  hasRaceState
  raceTime
}