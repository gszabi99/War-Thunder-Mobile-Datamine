from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/pServerApi.nut" import clan_get_user_token, registerHandler
from "%appGlobals/pServer/pServerJwt.nut" import decodeJwtAndHandleErrors
from "%appGlobals/userstats/serverTime.nut" import getServerTime, isServerTimeValid
from "%rGui/clans/currentClanState.nut" import currentClanId, hasConfirmedClan, NO_CLAN_ID


const RETRY_GET_TOKEN = 60
const TOKEN_LIFE_SEC = 300

let sourcesToRefreshToken = Watched({})
let delayTokenByErrorClanId = Watched(NO_CLAN_ID)
let clanToken = hardPersistWatched("clan.token", null)

let isClanTokenForCurrent = Computed(@() clanToken.get()?.payload.clanId == currentClanId.get())
let isDelayTokenByErrorForCurrent = Computed(@() delayTokenByErrorClanId.get() == currentClanId.get())

let needRefreshClanToken = Computed(function() {
  let needToken = sourcesToRefreshToken.get().len() > 0
  return needToken
    && hasConfirmedClan.get()
    && !isDelayTokenByErrorForCurrent.get()
    && !isClanTokenForCurrent.get()
})

let removeTokenErrorDelay = @() delayTokenByErrorClanId.set(NO_CLAN_ID)

function addTokenErrorDelay(clanId) {
  delayTokenByErrorClanId.set(clanId)
  resetTimeout(RETRY_GET_TOKEN, removeTokenErrorDelay)
}

registerHandler("onGetClanToken", function(res, context) {
  let { clanId } = context
  if (clanId != currentClanId.get())
    return
  if ("error" in res) {
    addTokenErrorDelay(clanId)
    return
  }
  let jwtRes = decodeJwtAndHandleErrors(res)
  if ("error" not in jwtRes) {
    removeTokenErrorDelay()
    clanToken.set(jwtRes)
  }
  else
    addTokenErrorDelay(clanId)
})

function updateToken() {
  if (!needRefreshClanToken.get())
    return
  clan_get_user_token(currentClanId.get(), { id = "onGetClanToken", clanId = currentClanId.get() })
}
updateToken()
needRefreshClanToken.subscribe(@(_) updateToken())

function updateClanTokenExpire() {
  if (clanToken.get() == null || !isServerTimeValid.get())
    return
  let curTime = getServerTime()
  let { iat = 0 } = clanToken.get()?.payload
  let timeLeft = iat + TOKEN_LIFE_SEC - curTime
  if (timeLeft <= 0)
    clanToken.set(null)
  else
    resetTimeout(timeLeft, updateClanTokenExpire)
}
updateClanTokenExpire()
clanToken.subscribe(@(_) updateClanTokenExpire())
isServerTimeValid.subscribe(@(_) updateClanTokenExpire())

isLoggedIn.subscribe(@(v) v ? null : clanToken.set(null))

function subscribeClanTokenNeed(sourceId, needToken) {
  sourcesToRefreshToken.mutate(@(s) needToken.get() ? s.$rawset(sourceId, true) : s.$rawdelete(sourceId))
  needToken.subscribe(@(nt) sourcesToRefreshToken.mutate(@(s) nt ? s.$rawset(sourceId, true) : s.$rawdelete(sourceId)))
}

return {
  TOKEN_LIFE_SEC

  clanToken

  isClanTokenForCurrent
  isDelayTokenByErrorForCurrent

  needRefreshClanToken

  addTokenErrorDelay

  subscribeClanTokenNeed
}