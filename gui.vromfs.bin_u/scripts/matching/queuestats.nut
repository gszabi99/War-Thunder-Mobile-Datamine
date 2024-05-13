from "%scripts/dagui_library.nut" import *

let { queueInfo, isInQueue } = require("%appGlobals/queueState.nut")
let matching = require("%appGlobals/matching_api.nut")

isInQueue.subscribe(@(v) v ? null : queueInfo(null))

//gather only playerCount atm, because not use other
function gatherStats(info) {
  let { byTeams = null } = info
  if (byTeams == null)
    return null
  let res = {}
  foreach (team in byTeams)
    foreach (country in team)
      foreach (rank, rankStats in country)
        res[rank] <- (res?[rank] ?? 0) + (rankStats?.cnt ?? 0)
  return res
}

matching.subscribe("match.update_queue_info", function(info) {
  let stats = gatherStats(info)
  if (stats == null)
    return
  let { cluster = null, queueId = null } = info
  if (cluster == null || queueId == null)
    return
  let qi = queueInfo.value ?? {}
  queueInfo(qi.__merge({
    [cluster] = (qi?[cluster] ?? {})
      .__merge({ [queueId] = stats })
  }))
})