from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import getCountryCode
from "dagor.workcycle" import resetTimeout
import "regexp2" as regexp2
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/defaultClusters.nut" import getForbiddenClustersByCountry
from "%appGlobals/loginState.nut" import isMatchingOnline
from "%rGui/matching/matchingApi.nut" import matching_subscribe, matchingRpcRegisterHandler
import "%rGui/matching/matchingRequestWithRetries.nut" as matchingRequestWithRetries


let logCH = log_with_prefix("[CLUSTER_HOSTS] ")

const MAX_FETCH_DELAY_SEC = 60
const OUT_OF_RETRIES_DELAY_SEC = 300

let clusterHosts = hardPersistWatched("clusterHosts", {})
let clusterHostsChangePending = hardPersistWatched("clusterHostsChangePending", {})
let canFetchHosts = Computed(@() isMatchingOnline.get() && !isInBattle.get())

let reIP = regexp2(@"^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$")

let getValidHosts = @(serverAnswer) serverAnswer.filter(function(clusters, ip) {
  if (!reIP.match(ip))
    return false
  let forbiddenClusters = getForbiddenClustersByCountry(getCountryCode())
  foreach (cluster in clusters)
    if (forbiddenClusters.contains(cluster))
      return false
  return true
})

let tryFetchHosts = @() !canFetchHosts.get() || clusterHosts.get().len() != 0 ? null
  : matchingRequestWithRetries({
      cmd = "hmanager.fetch_hosts_list"
      params = { timeout = MAX_FETCH_DELAY_SEC }
      isForced = true
      onFinish = "onClusterHostsFetched"
    })

matchingRpcRegisterHandler("onClusterHostsFetched", function(result) {
  if ("error" in result) {
    resetTimeout(OUT_OF_RETRIES_DELAY_SEC, tryFetchHosts)
    return
  }
  logCH($"Fetched hosts:", result)
  clusterHosts.set(getValidHosts(result))
})

canFetchHosts.subscribe(@(_) tryFetchHosts())

function tryApplyChangedHosts() {
  if (isInBattle.get() || clusterHostsChangePending.get().len() == 0)
    return
  logCH($"Applying changed hosts")
  clusterHosts.set(clusterHostsChangePending.get())
  clusterHostsChangePending.set({})
}

isInBattle.subscribe(@(_) tryApplyChangedHosts())

matching_subscribe("hmanager.notify_hosts_list_changed", function(result) {
  logCH($"Changed hosts:", result)
  clusterHostsChangePending.set(getValidHosts(result))
  tryApplyChangedHosts()
})

tryApplyChangedHosts()
tryFetchHosts()

return {
  clusterHosts
}
