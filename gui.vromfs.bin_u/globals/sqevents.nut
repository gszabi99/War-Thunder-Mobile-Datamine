//checked for explicitness
#no-root-fallback
#explicit-this
let { registerUnicastEvent, registerBroadcastEvent } = require("%sqstd/ecs.nut")
let dedicLogerrSqEvents = require("%globalScripts/debugTools/dedicLogerrSqEvents.nut")

let broadcastEvents = {}
foreach (name, payload in {
    EventResultMPlayers = {} //broadcast server to client
  })
  broadcastEvents.__update(registerBroadcastEvent(payload, name))

let unicastEvents = {}
foreach (name, payload in {
    CmdSetBattleJwtData = { jwtList = [] } //set from client
    CmdGetMyBattleData = {} //request from client
    CmdSetMyBattleData = {} //set from dedicated
    CmdSetDefaultBattleData = { dataId = "" } //set from client

    EventBattleResult = {} //server to client
    EventPlayerStats = {} //server to client
  })
  unicastEvents.__update(registerUnicastEvent(payload, name))

return freeze(broadcastEvents.__merge(unicastEvents, dedicLogerrSqEvents))
