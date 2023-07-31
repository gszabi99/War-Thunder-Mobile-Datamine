from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isContactOnline, onlineStatus } = require("contactPresence.nut")

let contactsListsMap = {
  friendsUids = "approved"
  myRequestsUids = "myRequests"
  requestsToMeUids = "requestsToMe"
  rejectedByMeUids = "rejectedByMe"
  myBlacklistUids = "myBlacklist"
  meInBlacklistUids = "meInBlacklist"
}

let contactsLists = {}
let export = {}
foreach(exportId, listId in contactsListsMap) {
  let list = hardPersistWatched($"contact_list.{listId}", {})
  export[exportId] <- list
  contactsLists[listId] <- list
}

let { friendsUids } = export
let friendsOnlineUids = Computed(@()
  friendsUids.value.filter(@(_, userId) isContactOnline(userId, onlineStatus.value)).keys()
)

return {
  contactsLists
  friendsOnlineUids
}.__update(export)