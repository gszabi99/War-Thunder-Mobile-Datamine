from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")

//todo: convert missionSq.cpp scipts register from globals to module
//tp avoid such strange requests to other VM.
let delayedPlayerActions = {}
subscribe("get_mplayer_by_id_result", function(msg) {
  let { id, player } = msg
  if (id not in delayedPlayerActions)
    return
  delayedPlayerActions[id](player)
  delete delayedPlayerActions[id]
})
let function rqPlayerAndDo(playerId, action) {
  delayedPlayerActions[playerId] <- action
  send("get_mplayer_by_id", { id = playerId })
}

//todo: convert missionSq.cpp scipts register from globals to module
//tp avoid such strange requests to other VM.
let delayedListActions = {}
local delayedIdx = 0
subscribe("get_mplayers_by_ids_result", function(msg) {
  let { uid, players } = msg
  if (uid not in delayedListActions)
    return
  delayedListActions[uid](players)
  delete delayedListActions[uid]
})
let function rqPlayersAndDo(players, action) {
  delayedListActions[++delayedIdx] <- action
  send("get_mplayers_by_ids", { players, uid = delayedIdx })
}

return {
  rqPlayerAndDo
  rqPlayersAndDo
}