//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let logC = log_with_prefix("[CLUSTERS] ")
let { getCountryCode } = require("auth_wt")
let { getClustersByCountry } = require("%appGlobals/defaultClusters.nut")
let { startLogout } = require("%scripts/login/logout.nut")
let showMatchingError = require("showMatchingError.nut")
let { isMatchingOnline } = require("matchingOnline.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { optimalClusters } = require("%scripts/matching/optimalClusters.nut")

const MAX_FETCH_RETRIES = 5
let clusters = mkHardWatched("matching.clusters", [])
local isFetching = false
local failedFetches = 0

let function applyClusters(res) {
  logC("clusters received", res)
  let newClusters = res?.clusters
  if (type(newClusters) != "array")
    return false
  clusters(newClusters)
  return newClusters.len() > 0
}

let function fetchClusters() {
  if (isFetching)
    return

  isFetching = true
  let again = callee()
  ::matching.rpc_call("wtmm_static.fetch_clusters_list", null,
    function(res) {
      isFetching = false
      if (res.error == OPERATION_COMPLETE && applyClusters(res)) {
        failedFetches = 0
        return
      }

      if (++failedFetches < MAX_FETCH_RETRIES) {
        logC($"fetch cluster error, retry - {failedFetches}")
        again()
      }
      else {
        showMatchingError(res)
        startLogout()
      }
    })
}

let function restartFetchClusters() {
  isFetching = false
  failedFetches = 0
  fetchClusters()
}

let function onClustersChanged(params) {
  logC("notify_clusters_changed")
  let list = clone clusters.value

  foreach (cluster in params?.removed ?? []) {
    let idx = list.indexof(cluster)
    if (idx != null)
      list.remove(idx)
  }

  foreach (cluster in params?.added ?? [])
    if (!list.contains(cluster))
      list.append(cluster)

  logC("clusters list updated", list)
  clusters(list)
}

let getClusterLocName = @(name) name.indexof("wthost") != null ? name
  : loc($"cluster/{name}")

::matching.subscribe("match.notify_clusters_changed", onClustersChanged)

if (isMatchingOnline.value && clusters.value.len() == 0)
  restartFetchClusters()

isMatchingOnline.subscribe(@(v) !v ? null : restartFetchClusters())
isLoggedIn.subscribe(@(v) v ? null : clusters([]))

let selClusters = Computed(function() {
  let fastest = optimalClusters.value.filter(@(c) clusters.value.contains(c))
  if (fastest.len())
    return fastest
  let defaults = getClustersByCountry(getCountryCode())
  let res = defaults.filter(@(c) clusters.value.contains(c))
  return res.len() ? res : clusters.value
})

return {
  clusters
  selClusters
  getClusterLocName
}