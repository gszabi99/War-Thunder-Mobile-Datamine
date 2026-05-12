let { registerUnicastEvent, registerBroadcastEvent } = require("%sqstd/ecs.nut")
let dedicLogerrSqEvents = require("%globalScripts/debugTools/dedicLogerrSqEvents.nut")

let broadcastEvents = {}
foreach (name, payload in {
    EventResultMPlayers = {} 
  })
  broadcastEvents.__update(registerBroadcastEvent(payload, name))

let unicastEvents = {}
foreach (name, payload in {
    CmdSetBattleJwtData = { jwtList = [] } 
    CmdGetMyBattleData = {} 
    CmdSetMyBattleData = {} 
    CmdSetDefaultBattleData = { dataId = "" } 

    EventBattleResult = {} 
    EventPlayerStats = {} 
  })
  unicastEvents.__update(registerUnicastEvent(payload, name))

return freeze(broadcastEvents.__merge(unicastEvents, dedicLogerrSqEvents))
