from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let presences = hardPersistWatched("contactPresence", {})

let calcStatus = @(presence) presence?.unknown ? null : presence?.online
let onlineStatus = Watched(presences.value.map(calcStatus))

let mkUpdatePresences = @(watch) function(newPresences) {
  if (newPresences.len() > 10) { //faster way when many presences received
    //merge and filter are much faster when receive a lot of friends then foreach with delete
    watch(watch.value.__merge(newPresences).filter(@(p) p != null))
    return
  }

  watch.mutate(function(v) {
    v.__update(newPresences)
    //it much faster than filter when update few presences of 2000 friends
    foreach (userId, presence in newPresences)
      if (presence == null)
        delete v[userId]
  })
}

let updatePresencesImpl = mkUpdatePresences(presences)
//here will be squad status

let function updatePresences(newPresences) {
  updatePresencesImpl(newPresences)
  onlineStatus.mutate(@(v) v.__update(newPresences.map(calcStatus)))
}
onlineStatus.whiteListMutatorClosure(updatePresences)

let function isContactOnline(userId, onlineStatusVal) {
  let uid = type(userId) == "integer" ? userId.tostring() : userId
  return onlineStatusVal?[uid] == true
}

let mkContactOnlineStatus = @(userId) Computed(@() onlineStatus.value?[userId])

return {
  presences
  onlineStatus
  updatePresences

  isContactOnline
  mkContactOnlineStatus
}