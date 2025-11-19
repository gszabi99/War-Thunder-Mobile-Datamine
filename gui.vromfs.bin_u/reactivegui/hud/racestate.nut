from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { get_mplayer_by_name, get_mission_time } = require("mission")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { isGtRace } = require("%rGui/missionState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

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
    let pExt = clone p
    if ("raceLap" not in p) {
      let mplayer = get_mplayer_by_name(p.name)
      pExt.raceLap <- mplayer?.raceLap ?? 0
      pExt.raceLastCheckpoint <- mplayer?.raceLastCheckpoint ?? 0
      pExt.raceFinishTime <- mplayer?.raceFinishTime ?? -1.0
    }
    local { raceLap, raceLastCheckpoint } = pExt
    pExt.progress <- total <= 0 ? -1
      : (100 * (max(0, raceLap - 1) * checkpointsPerLap + raceLastCheckpoint) / total).tointeger()
    res.append(prevIfEqual(prev?[res.len()], pExt))
  }
  return res
})
let raceCurrentLap = Computed(@() raceData.get()?.currentLap ?? 0)
let raceTotalLaps = Computed(@() raceData.get()?.totalLaps ?? 0)
let raceCurrentCheckpoint = Computed(@() raceData.get()?.passedCheckpointsInLap ?? 0)
let raceTotalCheckpoints = Computed(@() raceData.get()?.checkpointsPerLap ?? 0)

eventbus_subscribe("RaceSegmentUpdate", @(data) !isGtRace.get() ? null : raceData.set(data))
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

eventbus_subscribe("hint:missionHint:set", function(data) {
  if (isGtRace.get() && raceStartTime.get() == null && data?.locId == "hints/race_starts_in")
    raceStartTime.set(get_mission_time()) 
})

return {
  raceLeadershipPlayers
  raceCurrentLap
  raceTotalLaps
  raceCurrentCheckpoint
  raceTotalCheckpoints
  hasRaceState
  raceTime
}