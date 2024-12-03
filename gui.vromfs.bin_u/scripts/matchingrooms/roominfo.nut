from "%scripts/dagui_library.nut" import *

let { INVALID_ROOM_ID, INVALID_SQUAD_ID } = require("matching.errors")
let { squadLabels } = require("%appGlobals/squadLabelState.nut")
let { roomInfo } = require("%scripts/matchingRooms/sessionLobby.nut")


let lastLabelsRoomId = mkWatched(persist, "lastLabelsRoomId", INVALID_ROOM_ID)
roomInfo.subscribe(function(rInfo) {
  local nextLabel = {}
  local listSquads = {}
  local listPlayers = {}
  let isInNewRoom = rInfo && rInfo.roomId != lastLabelsRoomId.get()
  local playerLabels = !isInNewRoom ? clone squadLabels.get() : {}
  if (isInNewRoom)
    lastLabelsRoomId.set(rInfo.roomId)
  let players = rInfo?.public.filter(@(p) p?.squad) ?? {}
  foreach(player in players) {
    listPlayers[$"{player.id}"] <- player.squad
    if (player.team not in nextLabel)
      nextLabel[player.team] <- 1
    let squadId = player.squad
    if (squadId == INVALID_SQUAD_ID)
        continue
    if (squadId in listSquads) {
      listSquads[squadId] = nextLabel[player.team]
      nextLabel[player.team]++
    }
    else
      listSquads[squadId] <- -1
  }

  foreach (playerId, squadId in listPlayers){
    if (playerId in playerLabels)
      continue
    playerLabels[playerId] <- listSquads[squadId]
  }

  squadLabels.set(playerLabels)
})
