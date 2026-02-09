from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

let invitations = hardPersistWatched("invitations", [])
let counter = hardPersistWatched("invitationsCounter", 0)
let hasUnread = Computed(@() invitations.get().findvalue(@(i) !i.isRead) != null)
let hasImportantUnread = Computed(@() invitations.get().findvalue(@(i) !i.isRead && i.isImportant) != null)
let invitationsUids = Computed(@() invitations.get().map(@(v) [v.playerUid.tostring(), true]).totable())

let subscriptions = {}
function subscribeGroup(actionsGroup, actions) {
  if (actionsGroup in subscriptions || actionsGroup == "") {
    logerr($"Invitations already has subscriptions on actionsGroup {actionsGroup}")
    return
  }
  subscriptions[actionsGroup] <- actions
}

function removeNotifyById(id) {
  let idx = invitations.get().findindex(@(n) n.id == id)
  if (idx != null)
    invitations.mutate(@(value) value.remove(idx))
}

function removeNotify(notify) {
  let idx = invitations.get().indexof(notify)
  if (idx != null)
    invitations.mutate(@(value) value.remove(idx))
}

function onNotifyApply(uid) {
  let notify = invitations.get().findvalue(@(v) v.playerUid == uid)
  if (notify == null)
    return
  let onApply = subscriptions?[notify.actionsGroup].onApply ?? removeNotify
  onApply(notify)
}

function onNotifyRemove(uid) {
  let notify = invitations.get().findvalue(@(v) v.playerUid == uid)
  if (notify == null)
    return

  let onRemove = subscriptions?[notify.actionsGroup].onRemove
  onRemove?(notify)
  removeNotify(notify)
}

function clearAll() {
  let list = clone invitations.get()
  foreach (notify in list) {
    let onRemove = subscriptions?[notify.actionsGroup].onRemove
    onRemove?(notify)
  }
  invitations.set(invitations.get().filter(@(n) !list.contains(n)))
}

let NOTIFICATION_PARAMS = {
  id = null 
  time = 0 
  text = ""
  playerUid = null
  actionsGroup = ""
  isRead = false
  isImportant = false
  styleId = ""
}
function pushNotification(notify = NOTIFICATION_PARAMS) {
  notify = NOTIFICATION_PARAMS.__merge({ time = serverTime.get() }, notify)

  if (notify.id != null)
    removeNotifyById(notify.id)
  else {
    notify.id = $"_{counter.get()}"
    counter.set(counter.get() + 1)
  }

  invitations.mutate(@(v) v.append(notify))
}

function markReadAll() {
  if (hasUnread.get())
    invitations.mutate(@(v) v.each(@(notify) notify.isRead = true))
}

function markRead(uid) {
  let idx = invitations.get().findindex(@(n) n.playerUid == uid)
  if (idx != null && !invitations.get()[idx].isRead)
    invitations.mutate(@(v) v[idx] = v[idx].__merge({ isRead = true }))
}

isLoggedIn.subscribe(@(_) clearAll())

return {
  invitations
  hasUnread
  hasImportantUnread
  pushNotification
  removeNotifyById
  markReadAll
  markRead
  clearAll
  invitationsUids

  subscribeGroup
  onNotifyRemove
  onNotifyApply
}
