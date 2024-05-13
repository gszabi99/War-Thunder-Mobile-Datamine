from "%scripts/dagui_library.nut" import *
let logC = log_with_prefix("[CLUSTERS] ")
let { OPERATION_COMPLETE } = require("matching.errors")
let { getCountryCode } = require("auth_wt")
let { getClustersByCountry, getForbiddenClustersByCountry } = require("%appGlobals/defaultClusters.nut")
let { startLogout } = require("%scripts/login/logout.nut")
let showMatchingError = require("showMatchingError.nut")
let { isMatchingOnline } = require("matchingOnline.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { optimalClusters } = require("%scripts/matching/optimalClusters.nut")
let matching = require("%appGlobals/matching_api.nut")

const MAX_FETCH_RETRIES = 5
let clusters = hardPersistWatched("matching.clusters", [])
local isFetching = false
local failedFetches = 0

function getValidClusters(clustersList) {
  let forbiddenClusters = getForbiddenClustersByCountry(getCountryCode())
  return clustersList.filter(@(cluster) !forbiddenClusters.contains(cluster))
}

function applyClusters(res) {
  logC("clusters received", res)
  if (type(res?.clusters) != "array")
    return false
  let newClusters = getValidClusters(res.clusters)
  clusters(newClusters.len() == 0 ? res.clusters : newClusters)
  return clusters.value.len() > 0
}

function fetchClusters() {
  if (isFetching)
    return

  isFetching = true
  let again = callee()
  matching.rpc_call("wtmm_static.fetch_clusters_list", null,
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

function restartFetchClusters() {
  isFetching = false
  failedFetches = 0
  fetchClusters()
}

function onClustersChanged(params) {
  logC("notify_clusters_changed")
  let list = clone clusters.value

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
  clusters(list)
}

let getClusterLocName = @(name) name.indexof("wthost") != null ? name
  : loc($"cluster/{name}")

matching.subscribe("match.notify_clusters_changed", onClustersChanged)

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

selClusters.subscribe(@(v) logC("Selected clusters:", v))

return {
  clusters
  selClusters
  getClusterLocName
}