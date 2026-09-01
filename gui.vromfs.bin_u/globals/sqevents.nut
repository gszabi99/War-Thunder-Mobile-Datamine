from "%sqstd/ecs.nut" import registerUnicastEvent, registerBroadcastEvent
import "%globalScripts/debugTools/dedicLogerrSqEvents.nut" as dedicLogerrSqEvents


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
