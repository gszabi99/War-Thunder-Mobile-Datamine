from "%globalsDarg/darg_library.nut" import *
from "%rGui/matching/matchingApi.nut" import matching_subscribe
from "%appGlobals/queueState.nut" import queueInfo, isInQueue


isInQueue.subscribe(@(v) v ? null : queueInfo.set(null))


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

matching_subscribe("match.update_queue_info", function(info) {
  let stats = gatherStats(info)
  if (stats == null)
    return
  let { cluster = null, queueId = null } = info
  if (cluster == null || queueId == null)
    return
  let qi = queueInfo.get() ?? {}
  queueInfo.set(qi.__merge({
    [cluster] = (qi?[cluster] ?? {})
      .__merge({ [queueId] = stats })
  }))
})