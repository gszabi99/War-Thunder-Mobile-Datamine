from "%scripts/dagui_library.nut" import *
let logCH = log_with_prefix("[CLUSTER_HOSTS] ")
let { OPERATION_COMPLETE } = require("matching.errors")
let regexp2 = require("regexp2")
let { getCountryCode } = require("auth_wt")
let { resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { getForbiddenClustersByCountry } = require("%appGlobals/defaultClusters.nut")
let { isMatchingOnline } = require("%scripts/matching/matchingOnline.nut")
let matching = require("%appGlobals/matching_api.nut")

const MAX_FETCH_RETRIES = 5
const MAX_FETCH_DELAY_SEC = 60
const OUT_OF_RETRIES_DELAY_SEC = 300

let clusterHosts = hardPersistWatched("clusterHosts", {})
let clusterHostsChangePending = hardPersistWatched("clusterHostsChangePending", {})
let canFetchHosts = Computed(@() isMatchingOnline.value && !isInBattle.value)
local isFetching = false
local failedFetches = 0

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

function fetchClusterHosts() {
  if (!canFetchHosts.value || isFetching)
    return

  isFetching = true
  logCH($"fetchClusterHosts (try {failedFetches})")
  let again = callee()
  matching.rpc_call("hmanager.fetch_hosts_list",
    { timeout = MAX_FETCH_DELAY_SEC },
    function (result) {
      isFetching = false

      if (result.error == OPERATION_COMPLETE) {
        logCH($"Fetched hosts:", result)
        failedFetches = 0
        clusterHosts(getValidHosts(result))
        return
      }

      failedFetches++
      if (failedFetches < MAX_FETCH_RETRIES)
        resetTimeout(0.1, again)
      else {
        failedFetches = 0
        resetTimeout(OUT_OF_RETRIES_DELAY_SEC, again)
      }
    })
}

function tryFetchHosts() {
  isFetching = false
  failedFetches = 0
  if (canFetchHosts.value && clusterHosts.value.len() == 0)
    fetchClusterHosts()
}

canFetchHosts.subscribe(@(_) tryFetchHosts())

function tryApplyChangedHosts() {
  if (isInBattle.value || clusterHostsChangePending.value.len() == 0)
    return
  logCH($"Applying changed hosts")
  clusterHosts(clusterHostsChangePending.value)
  clusterHostsChangePending({})
}

isInBattle.subscribe(@(_) tryApplyChangedHosts())

matching.subscribe("hmanager.notify_hosts_list_changed", function(result) {
  logCH($"Changed hosts:", result)
  clusterHostsChangePending(getValidHosts(result))
  tryApplyChangedHosts()
})

tryApplyChangedHosts()
tryFetchHosts()

return {
  clusterHosts
}
