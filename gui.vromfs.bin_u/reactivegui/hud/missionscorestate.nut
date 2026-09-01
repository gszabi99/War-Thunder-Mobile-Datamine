from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle, localMPlayerTeam
from "%appGlobals/clientState/missionState.nut" import missionProgressType
from "%rGui/hud/missionVariableState.nut" import mkMissionVar


let missionScoresTable = mkWatched(persist, "missionScoresTable", {})
let isCTFProgressType = Computed(@() missionProgressType.get() == "CTF")
let isTeam1FlagStolen = mkMissionVar("t1_flag_stolen", false)
let isTeam2FlagStolen = mkMissionVar("t2_flag_stolen", false)

isInBattle.subscribe(@(_) missionScoresTable.set({}))

eventbus_subscribe("setMissionScore", function(ev) {
  let { id, visible } = ev
  let data = visible ? ev : null
  if (!isEqual(data, missionScoresTable.get()?[id]))
    missionScoresTable.mutate(@(v) visible
      ? v[id] <- data
      : v.$rawdelete(id))
})

let isFlagStolen = keepref(Computed(@() localMPlayerTeam.get() == 1 ? isTeam1FlagStolen.get()
  : isTeam2FlagStolen.get()))

return {
  missionScoresTable,
  isFlagStolen,
  isCTFProgressType,
  isNotCTFProgressType = Computed(@() !isCTFProgressType.get())
}
