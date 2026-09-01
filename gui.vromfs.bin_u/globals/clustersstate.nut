from "%globalScripts/logs.nut" import *
from "auth_wt" import getCountryCode
from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send
from "frp" import Computed
from "%sqstd/datablock.nut" import copyParamsToTable
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/defaultClusters.nut" import getClustersByCountry
from "%appGlobals/loginState.nut" import isSettingsAvailable
from "%appGlobals/permissions.nut" import allow_clusters_selection


const OPTIMAL_RTT_LIMIT_MS = 100 
const OPTIMAL_RTT_LIMIT_MS_SQUAD = 150 
const REACHABILITY_CHECK_TIMEOUT_SEC = 1 
const CAN_USER_DISABLE_FASTEST_CLUSTER = false

const USER_CLUSTERS_SAVE_ID = "clusters"
const CURRENT_SAVE_CFG_VERSION = 2

let clustersRaw = hardPersistWatched("matching.clusters", [])
let clusterStats = hardPersistWatched("clusterStats", [])
let optimalClusters = hardPersistWatched("optimalClusters", [])
let unreachableHosts = hardPersistWatched("unreachableHosts", [])
let lastReachabilityUpdateTimeMs = hardPersistWatched("lastReachabilityUpdateTimeMs", 0)
let fastestClusterId = Computed(@() clusterStats.get()?[0].clusterId ?? "")
let userPreferredClusters = hardPersistWatched("userPreferredClusters", {})
let isWaitingManualRefresh = hardPersistWatched("isWaitingManualRefresh", false)

let selClusters = Computed(function() {
  local res = []
  let validClusters = clustersRaw.get()
  let isValid = @(id) validClusters.contains(id)
  let fastest = optimalClusters.get().filter(isValid)
  if (fastest.len())
    res = fastest
  else {
    let defaults = getClustersByCountry(getCountryCode()).filter(isValid)
    res = defaults.len() ? defaults : (clone validClusters)
  }
  if (allow_clusters_selection.get()) {
    let userClusters = clone res
    foreach (id, v in userPreferredClusters.get())
      if (v == false && userClusters.contains(id)
          && (CAN_USER_DISABLE_FASTEST_CLUSTER || id != fastestClusterId.get())) 
        res.remove(res.indexof(id))
    if (userClusters.len())
      res = userClusters
  }
  return res
})

function clustersRefreshNow(needResetRtt, isManual) {
  eventbus_send("clusters_refresh_now", { needResetRtt, isManual })
}

function loadUserClusters(needLoad) {
  if (!needLoad)
    return userPreferredClusters.set({})
  let data = copyParamsToTable(get_local_custom_settings_blk()?[USER_CLUSTERS_SAVE_ID])
  userPreferredClusters.set(data?._ver == CURRENT_SAVE_CFG_VERSION
    ? data.filter(@(_, k) k != "_ver"
        && (CAN_USER_DISABLE_FASTEST_CLUSTER || k != fastestClusterId.get())) 
    : {})
}
isSettingsAvailable.subscribe(loadUserClusters)
loadUserClusters(isSettingsAvailable.get())

function saveUserClusters() {
  if (!allow_clusters_selection.get())
    return
  get_local_custom_settings_blk().removeBlock(USER_CLUSTERS_SAVE_ID)
  if (userPreferredClusters.get().len() != 0) {
    let blk = get_local_custom_settings_blk().addBlock(USER_CLUSTERS_SAVE_ID)
    blk._ver = CURRENT_SAVE_CFG_VERSION
    userPreferredClusters.get().each(@(v, id) blk[id] = v)
  }
  eventbus_send("saveProfile", {})
}

fastestClusterId.subscribe(function(v) {
  if (!CAN_USER_DISABLE_FASTEST_CLUSTER && (v in userPreferredClusters.get())) {
    userPreferredClusters.mutate(@(o) o.$rawdelete(v))
    saveUserClusters()
  }
})

return {
  OPTIMAL_RTT_LIMIT_MS
  OPTIMAL_RTT_LIMIT_MS_SQUAD
  REACHABILITY_CHECK_TIMEOUT_SEC
  CAN_USER_DISABLE_FASTEST_CLUSTER

  selClusters
  clusterStats
  clustersRaw
  optimalClusters
  unreachableHosts
  lastReachabilityUpdateTimeMs
  fastestClusterId
  userPreferredClusters
  isWaitingManualRefresh

  clustersRefreshNow
  saveUserClusters
}
