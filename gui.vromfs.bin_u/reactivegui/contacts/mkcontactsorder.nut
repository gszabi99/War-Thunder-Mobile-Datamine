from "%globalsDarg/darg_library.nut" import *
let { isEqual } = require("%sqstd/underscore.nut")
let { allContacts } = require("%rGui/contacts/contact.nut")
let { onlineStatus } = require("%rGui/contacts/contactPresence.nut")

let priorityByStatus = {
  [true] = 2,
  [false] = 1,
}

let mkContactsOrderImpl = @(uids) Computed(function(prev) {
  let uidsArr = type(uids.value) == "table" ? uids.value.keys() : uids.value
  let priorities = {}
  foreach(uid in uidsArr)
    priorities[uid] <- priorityByStatus?[onlineStatus.get()?[uid]] ?? -1
  let list = uidsArr.map(@(uid) allContacts.get()?[uid] ?? { realnick = "", userId = uid })
  list.sort(@(a, b) priorities[b.userId] <=> priorities[a.userId]
    || a.realnick <=> b.realnick)
  let res = list.map(@(v) v.userId)
  return isEqual(prev, res) ? prev : res
})

let mkContactsOrder = @(uidsOrWatch) uidsOrWatch instanceof Watched
  ? mkContactsOrderImpl(uidsOrWatch)
  : mkContactsOrderImpl(Watched(uidsOrWatch))

return mkContactsOrder