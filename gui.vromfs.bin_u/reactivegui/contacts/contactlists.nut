from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isContactOnline, onlineStatus } = require("%rGui/contacts/contactPresence.nut")

let contactsListsMap = {
  friendsUids = "approved"
  myRequestsUids = "myRequests"
  requestsToMeUids = "requestsToMe"
  rejectedByMeUids = "rejectedByMe"
  myBlacklistUids = "myBlacklist"
  meInBlacklistUids = "meInBlacklist"
  wtmLink = "wtmlink_g"
}

let contactsLists = {}
let export = {}
foreach(exportId, listId in contactsListsMap) {
  let list = hardPersistWatched($"contact_list.{listId}", {})
  export[exportId] <- list
  contactsLists[listId] <- list
}

let { friendsUids, wtmLink } = export
let friendsOnlineUids = Computed(@()
  friendsUids.get().filter(@(_, userId) isContactOnline(userId, onlineStatus.get())).keys()
)

let accountLink = Computed(@() wtmLink.get().findvalue(@(_) true))
accountLink.subscribe(@(a) log("Found account link: ", a))

return {
  contactsLists
  friendsOnlineUids
  accountLink
}.__update(export)