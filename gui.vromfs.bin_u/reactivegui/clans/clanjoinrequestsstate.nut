from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/initialState.nut" import projectId
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/pServer/pServerApi.nut" import registerHandler, get_user_join_requests, clanUserJoinRequestsInProgress
from "%sqstd/globalState.nut" import hardPersistWatched
from "%rGui/clans/clanState.nut" import handleClanError
from "%rGui/clans/currentClanState.nut" import shouldUpdateUserRequests, needUpdateUserRequests


const CLAN_USER_JOIN_REQUESTS = "clan_user_join_requests"

let userClanJoinRequests = hardPersistWatched("userClanRequests", null)
let shouldFetchRequests = keepref(Computed(@() needUpdateUserRequests.get()
  && !isInBattle.get()
  && !clanUserJoinRequestsInProgress.get()
))

function fetchUserJoinRequests() {
  shouldUpdateUserRequests.set(false)
  get_user_join_requests(projectId, {id = CLAN_USER_JOIN_REQUESTS})
}

shouldFetchRequests.subscribe(function(v) {
  if (v)
    fetchUserJoinRequests()
})

registerHandler(CLAN_USER_JOIN_REQUESTS, function(res) {
  if (!handleClanError(res))
    userClanJoinRequests.set((res?.requests ?? []).reduce(function(requests, val){
      requests[val.clanId] <- val
      return requests
    }, {}))
})

if (shouldFetchRequests.get())
  fetchUserJoinRequests()


return {
  userClanJoinRequests
}
