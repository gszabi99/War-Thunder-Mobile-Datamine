from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import getCountryCode
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_send
from "%appGlobals/clustersState.nut" import clustersRaw, selClusters
from "%appGlobals/defaultClusters.nut" import getForbiddenClustersByCountry
from "%appGlobals/loginState.nut" import isMatchingConnected, isLoggedIn
from "%rGui/matching/matchingApi.nut" import matching_subscribe, matchingRpcRegisterHandler
import "%rGui/matching/matchingRequestWithRetries.nut" as matchingRequestWithRetries
import "showMatchingError.nut" as showMatchingError
from "types" import Array


let logC = log_with_prefix("[CLUSTERS] ")
let requestLogout = @() eventbus_send("logOut", {})

function getValidClusters(clustersList) {
  let forbiddenClusters = getForbiddenClustersByCountry(getCountryCode())
  return clustersList.filter(@(cluster) !forbiddenClusters.contains(cluster))
}

let restartFetchClusters = @() matchingRequestWithRetries({
  cmd = "wtmm_static.fetch_clusters_list"
  params = null
  isForced = true
  onFinish = "onClustersListFetched"
})

matchingRpcRegisterHandler("onClustersListFetched", function(result) {
  if ("error" in result) {
    showMatchingError(result)
    deferOnce(requestLogout)
    return
  }
  logC("clusters received", result)
  if (!(result?.clusters instanceof Array))
    return
  let newClusters = getValidClusters(result.clusters)
  clustersRaw.set(newClusters.len() == 0 ? result.clusters : newClusters)
})

function onClustersChanged(params) {
  logC("notify_clusters_changed")
  let list = clone clustersRaw.get()

  foreach (cluster in params?.removed ?? []) {
    let idx = list.indexof(cluster)
    if (idx != null)
      list.remove(idx)
  }

  let { added = [] } = params
  foreach (cluster in getValidClusters(added))
    if (!list.contains(cluster))
      list.append(cluster)

  if (list.len() == 0)
    list.extend(added)

  logC("clusters list updated", list)
  clustersRaw.set(list)
}

matching_subscribe("match.notify_clusters_changed", onClustersChanged)

if (isMatchingConnected.get() && clustersRaw.get().len() == 0)
  restartFetchClusters()

isMatchingConnected.subscribe(@(v) !v ? null : restartFetchClusters())
isLoggedIn.subscribe(@(v) v ? null : clustersRaw.set([]))

selClusters.subscribe(@(v) logC($"Country \"{getCountryCode()}\", selected clusters:", v))
