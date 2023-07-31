
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let lobbyStates = {
  NOT_IN_ROOM             = 0
  WAIT_FOR_QUEUE_ROOM     = 1
  CREATING_ROOM           = 2
  JOINING_ROOM            = 3
  IN_ROOM                 = 4
  IN_LOBBY                = 5
  IN_LOBBY_HIDDEN         = 6 //in lobby, but hidden by joining wnd. Used when lobby after queue before session
  UPLOAD_CONTENT          = 7
  START_SESSION           = 8
  JOINING_SESSION         = 9
  IN_SESSION              = 10
  IN_DEBRIEFING           = 11
}

let sessionLobbyStatus = sharedWatched("sessionLobbyStatus", @() lobbyStates.NOT_IN_ROOM)

let notInJoiningGameStatuses = [
 lobbyStates.NOT_IN_ROOM
 lobbyStates.IN_LOBBY
 lobbyStates.IN_SESSION
 lobbyStates.IN_DEBRIEFING
]

let notInRoomStatuses = [
 lobbyStates.NOT_IN_ROOM
 lobbyStates.WAIT_FOR_QUEUE_ROOM
 lobbyStates.CREATING_ROOM
 lobbyStates.JOINING_ROOM
]

return {
  lobbyStates
  sessionLobbyStatus
  isInJoiningGame = Computed(@() !notInJoiningGameStatuses.contains(sessionLobbyStatus.value))
  isInRoom = Computed(@() !notInRoomStatuses.contains(sessionLobbyStatus.value))
}