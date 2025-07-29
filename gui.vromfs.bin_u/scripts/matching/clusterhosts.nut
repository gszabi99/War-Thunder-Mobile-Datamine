from "%scripts/dagui_library.nut" import *
let logCH = log_with_prefix("[CLUSTER_HOSTS] ")
let regexp2 = require("regexp2")
let { getCountryCode } = require("auth_wt")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { getForbiddenClustersByCountry } = require("%appGlobals/defaultClusters.nut")
let { isMatchingOnline } = require("%scripts/matching/matchingOnline.nut")
let { matching_subscribe } = require("%appGlobals/matching_api.nut")
let matchingRequestWithRetries = require("%scripts/matching/matchingRequestWithRetries.nut")

const MAX_FETCH_DELAY_SEC = 60
const OUT_OF_RETRIES_DELAY_SEC = 300

let clusterHosts = hardPersistWatched("clusterHosts", {})
let clusterHostsChangePending = hardPersistWatched("clusterHostsChangePending", {})
let canFetchHosts = Computed(@() isMatchingOnline.value && !isInBattle.get())

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

let tryFetchHosts = @() !canFetchHosts.get() || clusterHosts.get().len() != 0 ? null : matchingRequestWithRetries({
    cmd = "hmanager.fetch_hosts_list"
    params = { timeout = MAX_FETCH_DELAY_SEC }
    isForced = true
    function onSuccess(result) {
      logCH($"Fetched hosts:", result)
      clusterHosts.set(getValidHosts(result))
    }
    outOfRetriesDelaySec = OUT_OF_RETRIES_DELAY_SEC
  })

canFetchHosts.subscribe(@(_) tryFetchHosts())

function tryApplyChangedHosts() {
  if (isInBattle.get() || clusterHostsChangePending.value.len() == 0)
    return
  logCH($"Applying changed hosts")
  clusterHosts(clusterHostsChangePending.value)
  clusterHostsChangePending({})
}

isInBattle.subscribe(@(_) tryApplyChangedHosts())

matching_subscribe("hmanager.notify_hosts_list_changed", function(result) {
  logCH($"Changed hosts:", result)
  clusterHostsChangePending(getValidHosts(result))
  tryApplyChangedHosts()
})

tryApplyChangedHosts()
tryFetchHosts()

return {
  clusterHosts
}
