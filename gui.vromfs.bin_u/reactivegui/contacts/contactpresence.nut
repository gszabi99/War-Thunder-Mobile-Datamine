from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let presences = hardPersistWatched("contactPresence", {})
let squadStatus = hardPersistWatched("contactSquadStatus", {})

let calcStatus = @(presence) presence?.unknown ? null : presence?.online
let onlineStatusBase = Watched(presences.value.map(calcStatus))

let onlineStatus = Computed(@() onlineStatusBase.value.__merge(squadStatus.value))

let mkUpdatePresences = @(watch) function(newPresences) {
  if (newPresences.len() > 10) { 
    
    watch(watch.value.__merge(newPresences).filter(@(p) p != null))
    return
  }

  watch.mutate(function(v) {
    v.__update(newPresences)
    
    foreach (userId, presence in newPresences)
      if (presence == null)
        v.$rawdelete(userId)
  })
}

let updatePresencesImpl = mkUpdatePresences(presences)
let updateSquadPresences = mkUpdatePresences(squadStatus)

function updatePresences(newPresences) {
  updatePresencesImpl(newPresences)
  onlineStatusBase.mutate(@(v) v.__update(newPresences.map(calcStatus)))
}
onlineStatusBase.whiteListMutatorClosure(updatePresences)

function isContactOnline(userId, onlineStatusVal) {
  let uid = type(userId) == "integer" ? userId.tostring() : userId
  return onlineStatusVal?[uid] == true
}

let mkContactOnlineStatus = @(userId) Computed(@() onlineStatus.value?[userId])

return {
  presences
  onlineStatus
  updatePresences
  updateSquadPresences

  isContactOnline
  mkContactOnlineStatus
}