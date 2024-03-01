from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *

let playersCommonStats = Watched({})
let dbgCommonStats = mkWatched(persist, "dbgCommonStats", {})

register_es("players_common_stats_es",
  {
    [["onInit", "onChange"]] = function trackStatistics(_, comp) {
      if (comp.isBattleDataReceived)
        playersCommonStats.mutate(@(v) v[comp.server_player__userId] <- comp.commonStats.getAll())
    },
  },
  {
    comps_track = [
      ["commonStats", TYPE_OBJECT],
      ["isBattleDataReceived", TYPE_BOOL],
    ],
    comps_ro = [["server_player__userId", TYPE_UINT64]],
  })

return {
  playersCommonStats = Computed(@() playersCommonStats.value.__merge(dbgCommonStats.value))
  dbgCommonStats
}
