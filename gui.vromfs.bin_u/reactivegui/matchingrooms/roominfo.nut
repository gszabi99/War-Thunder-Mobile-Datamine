from "%globalsDarg/darg_library.nut" import *
from "matching.errors" import INVALID_ROOM_ID, INVALID_SQUAD_ID
from "%appGlobals/squadLabelState.nut" import squadLabels
from "%rGui/matchingRooms/sessionLobby.nut" import roomInfo


let lastLabelsRoomId = mkWatched(persist, "lastLabelsRoomId", INVALID_ROOM_ID)
let seenSquadPlayers = mkWatched(persist, "seenSquadPlayers", {})
let squadLabelById = mkWatched(persist, "squadLabelById", {})

roomInfo.subscribe(function(rInfo) {
  if (rInfo == null)
    return
  let isInNewRoom = rInfo.roomId != lastLabelsRoomId.get()
  if (isInNewRoom)
    lastLabelsRoomId.set(rInfo.roomId)
  let seen = isInNewRoom ? {} : clone seenSquadPlayers.get()
  foreach (p in rInfo?.public ?? {})
    if ((p?.squad ?? INVALID_SQUAD_ID) != INVALID_SQUAD_ID)
      seen[$"{p.id}"] <- { squad = p.squad, team = p.team }
  seenSquadPlayers.set(seen)

  let squadTeam = {}
  let squadSize = {}
  foreach (p in seen) {
    squadTeam[p.squad] <- p.team
    squadSize[p.squad] <- (squadSize?[p.squad] ?? 0) + 1
  }
  let squadLabel = isInNewRoom ? {} : clone squadLabelById.get()
  let newSquads = squadSize.keys().filter(@(s) s not in squadLabel && squadSize[s] > 1).sort()
  foreach (squad in newSquads) {
    let team = squadTeam[squad]
    squadLabel[squad] <- squadLabel.filter(@(_, s) squadTeam[s] == team).len() + 1
  }
  squadLabelById.set(squadLabel)
  squadLabels.set(seen.map(@(p) squadLabel?[p.squad] ?? -1))
})
