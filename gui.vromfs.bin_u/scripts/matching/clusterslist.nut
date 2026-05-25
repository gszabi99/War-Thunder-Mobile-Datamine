from "%scripts/dagui_library.nut" import *
let logC = log_with_prefix("[CLUSTERS] ")
let { getCountryCode } = require("auth_wt")
let { deferOnce } = require("dagor.workcycle")
let { getForbiddenClustersByCountry } = require("%appGlobals/defaultClusters.nut")
let { startLogout } = require("%scripts/login/loginStart.nut")
let showMatchingError = require("showMatchingError.nut")
let { isMatchingConnected, isLoggedIn } = require("%appGlobals/loginState.nut")
let { clustersRaw, selClusters } = require("%appGlobals/clustersState.nut")
let { matching_subscribe } = require("%appGlobals/matching_api.nut")
let matchingRequestWithRetries = require("%scripts/matching/matchingRequestWithRetries.nut")

function getValidClusters(clustersList) {
  let forbiddenClusters = getForbiddenClustersByCountry(getCountryCode())
  return clustersList.filter(@(cluster) !forbiddenClusters.contains(cluster))
}

let restartFetchClusters = @() matchingRequestWithRetries({
    cmd = "wtmm_static.fetch_clusters_list"
    params = null
    isForced = true
    function onSuccess(result) {
      logC("clusters received", result)
      if (type(result?.clusters) != "array")
        return
      let newClusters = getValidClusters(result.clusters)
      clustersRaw.set(newClusters.len() == 0 ? result.clusters : newClusters)
    }
    function onError(result) {
      showMatchingError(result)
      deferOnce(startLogout)
    }
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
