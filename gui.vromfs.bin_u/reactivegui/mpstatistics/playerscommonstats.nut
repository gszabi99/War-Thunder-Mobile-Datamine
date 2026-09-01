from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
from "ecs.computed" import mkEcsComputedEidMap

let dbgCommonStats = mkWatched(persist, "dbgCommonStats", {})


let commonStatsByEid = mkEcsComputedEidMap({
  comps = [
    ["commonStats", TYPE_OBJECT],
    ["server_player__userId", TYPE_UINT64],
  ]
  comps_filter = [["isBattleDataReceived", TYPE_BOOL]]
  filter = "isBattleDataReceived"
})


let playersCommonStats = Computed(function() {
  let res = {}
  foreach (row in commonStatsByEid.get())
    res[row.server_player__userId] <- row.commonStats
  return res
})

return {
  playersCommonStats = Computed(@() playersCommonStats.get().__merge(dbgCommonStats.get()))
  dbgCommonStats
}
