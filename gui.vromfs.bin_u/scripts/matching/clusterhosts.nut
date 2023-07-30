from "%scripts/dagui_library.nut" import *
let logCH = log_with_prefix("[CLUSTER_HOSTS] ")
let regexp2 = require("regexp2")
let { resetTimeout } = require("dagor.workcycle")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isMatchingOnline } = require("%scripts/matching/matchingOnline.nut")

const MAX_FETCH_RETRIES = 5
const MAX_FETCH_DELAY_SEC = 60
const OUT_OF_RETRIES_DELAY_SEC = 300

let clusterHosts = mkHardWatched("clusterHosts", {})
let clusterHostsChangePending = mkHardWatched("clusterHostsChangePending", {})
let canFetchHosts = Computed(@() isMatchingOnline.value && !isInBattle.value)
local isFetching = false
local failedFetches = 0

let reIP = regexp2(@"^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$")

let function fetchClusterHosts() {
  if (!canFetchHosts.value || isFetching)
    return

  isFetching = true
  logCH($"fetchClusterHosts (try {failedFetches})")
  let again = callee()
  ::matching.rpc_call("hmanager.fetch_hosts_list",
    { timeout = MAX_FETCH_DELAY_SEC },
    function (result) {
      isFetching = false

      if (result.error == OPERATION_COMPLETE) {
        failedFetches = 0
        let hosts = result.filter(@(_, ip) reIP.match(ip))
        logCH($"Fetched hosts:")
        hosts.each(@(clusterNames, ip) logCH($"{ip} = [{",".join(clusterNames)}]"))
        clusterHosts(hosts)
        return
      }

      if (++failedFetches <= MAX_FETCH_RETRIES)
        resetTimeout(0.1, again)
      else {
        failedFetches = 0
        resetTimeout(OUT_OF_RETRIES_DELAY_SEC, again)
      }
    })
}

let function tryFetchHosts() {
  isFetching = false
  failedFetches = 0
  if (canFetchHosts.value && clusterHosts.value.len() == 0)
    fetchClusterHosts()
}

canFetchHosts.subscribe(@(_) tryFetchHosts())

let function tryApplyChangedHosts() {
  if (isInBattle.value || clusterHostsChangePending.value.len() == 0)
    return
  logCH($"Applying changed hosts")
  clusterHosts(clusterHostsChangePending.value)
  clusterHostsChangePending({})
}

isInBattle.subscribe(@(_) tryApplyChangedHosts())

::matching.subscribe("hmanager.notify_hosts_list_changed", function(result) {
  let hosts = result.filter(@(_, ip) reIP.match(ip))
  logCH($"Changed hosts:")
  hosts.each(@(clusterNames, ip) logCH($"{ip} = [{",".join(clusterNames)}]"))
  clusterHostsChangePending(hosts)
  tryApplyChangedHosts()
})

tryApplyChangedHosts()
tryFetchHosts()

return {
  clusterHosts
}
