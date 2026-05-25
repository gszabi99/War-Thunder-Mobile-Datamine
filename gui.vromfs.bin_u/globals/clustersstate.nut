from "%globalScripts/logs.nut" import *
from "frp" import Computed
from "eventbus" import eventbus_send
from "blkGetters" import get_local_custom_settings_blk
from "auth_wt" import getCountryCode
from "%sqstd/datablock.nut" import copyParamsToTable
import "%globalScripts/sharedWatched.nut" as sharedWatched
from "%appGlobals/permissions.nut" import allow_clusters_selection
from "%appGlobals/loginState.nut" import isSettingsAvailable
from "%appGlobals/defaultClusters.nut" import getClustersByCountry

const OPTIMAL_RTT_LIMIT_MS = 100 
const OPTIMAL_RTT_LIMIT_MS_SQUAD = 100 

const USER_CLUSTERS_SAVE_ID = "clusters"

let clustersRaw = sharedWatched("matching.clusters", @() [])
let clusterStats = sharedWatched("clusterStats", @() [])
let optimalClusters = sharedWatched("optimalClusters", @() [])
let userPreferredClusters = sharedWatched("userPreferredClusters", @() {})

let selClusters = Computed(function() {
  local res = []
  let validClusters = clustersRaw.get()
  let fastest = optimalClusters.get().filter(@(id) validClusters.contains(id))
  if (fastest.len())
    res = fastest
  else {
    let defaults = getClustersByCountry(getCountryCode())
      .filter(@(id) validClusters.contains(id))
    res = defaults.len() ? defaults : validClusters
  }
  if (allow_clusters_selection.get()) {
    let resBeforeUserPref = clone res
    foreach (id, v in userPreferredClusters.get()) {
      if (v == true && !res.contains(id) && validClusters.contains(id))
        res.append(id)
      if (v == false && res.contains(id))
        res.remove(res.indexof(id))
    }
    if (!res.len())
      res = resBeforeUserPref
  }
  return res
})

let loadUserClusters = @(needLoad) userPreferredClusters.set(needLoad
  ? copyParamsToTable(get_local_custom_settings_blk()?[USER_CLUSTERS_SAVE_ID])
  : {})
isSettingsAvailable.subscribe(loadUserClusters)
loadUserClusters(isSettingsAvailable.get())

function saveUserClusters() {
  if (!allow_clusters_selection.get())
    return
  let blk = get_local_custom_settings_blk().addBlock(USER_CLUSTERS_SAVE_ID)
  userPreferredClusters.get().each(@(v, id) blk[id] = v)
  eventbus_send("saveProfile", {})
}

return {
  OPTIMAL_RTT_LIMIT_MS
  OPTIMAL_RTT_LIMIT_MS_SQUAD

  selClusters
  clusterStats
  clustersRaw
  optimalClusters
  userPreferredClusters

  saveUserClusters
}
