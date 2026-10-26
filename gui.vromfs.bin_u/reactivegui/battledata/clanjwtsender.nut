from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
from "%sqstd/string.nut" import splitStringBySize
from "%appGlobals/sqevents.nut" import mkCmdSetClanJwtId
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/userstats/serverTime.nut" import getServerTime
from "%rGui/clans/clanToken.nut" import clanToken, TOKEN_LIFE_SEC, isClanTokenForCurrent, subscribeClanTokenNeed


let logC = log_with_prefix("[CLAN_JWT_SENDER] ")

let isClanIdReceived = Watched(false)
let serverPlayerEid = Watched(null)

let needSendClanToken = Computed(@() !isClanIdReceived.get() && serverPlayerEid.get() != null)
let needRequestClanToken = keepref(Computed(@() needSendClanToken.get() && clanToken.get() == null))

subscribeClanTokenNeed("clanJwtSender", needRequestClanToken)

function sendJwt() {
  let { jwt = null, payload = null } = clanToken.get()
  if (jwt == null || !needSendClanToken.get() || !isClanTokenForCurrent.get())
    return

  if ((payload?.iat ?? 0) + TOKEN_LIFE_SEC - getServerTime() <= 0) {
    logC($"Token is old on send clan id")
    return
  }

  logC("Send clan id")
  client_request_unicast_net_sqevent(serverPlayerEid.get(),
    mkCmdSetClanJwtId({ jwtList = splitStringBySize(jwt, 4096) }))
}
sendJwt()
clanToken.subscribe(@(_) sendJwt())
needSendClanToken.subscribe(@(_) sendJwt())

register_es("player_clan_id_es",
  {
    [["onInit", "onChange"]] = function(eid, comp) {
      let userId = comp.server_player__userId
      if (userId != myUserId.get())
        return
      logC($"isClanIdReceived = {comp.isClanIdReceived} (eid = {eid})")
      isClanIdReceived.set(comp.isClanIdReceived)
      serverPlayerEid.set(eid)
    },
    function onDestroy(_eid, comp) {
      let userId = comp.server_player__userId
      if (userId != myUserId.get())
        return
      isClanIdReceived.set(false)
      serverPlayerEid.set(null)
    }
  },
  {
    comps_ro = [["server_player__userId", TYPE_UINT64]]
    comps_track = [["isClanIdReceived", TYPE_BOOL]]
  })