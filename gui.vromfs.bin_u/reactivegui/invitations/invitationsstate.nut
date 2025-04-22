from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

let isInvitationsOpened = mkWatched(persist, "isInvitationsOpened", false)
let invitations = hardPersistWatched("invitations", [])
let counter = hardPersistWatched("invitationsCounter", 0)
let hasUnread = Computed(@() invitations.value.findvalue(@(i) !i.isRead) != null)
let hasImportantUnread = Computed(@() invitations.value.findvalue(@(i) !i.isRead && i.isImportant) != null)

let subscriptions = {}
function subscribeGroup(actionsGroup, actions) {
  if (actionsGroup in subscriptions || actionsGroup == "") {
    logerr($"Invitations already has subscriptions on actionsGroup {actionsGroup}")
    return
  }
  subscriptions[actionsGroup] <- actions
}

function removeNotifyById(id) {
  let idx = invitations.value.findindex(@(n) n.id == id)
  if (idx != null)
    invitations.mutate(@(value) value.remove(idx))
}

function removeNotify(notify) {
  let idx = invitations.value.indexof(notify)
  if (idx != null)
    invitations.mutate(@(value) value.remove(idx))
}

function onNotifyApply(notify) {
  if (!invitations.value.contains(notify))
    return
  let onApply = subscriptions?[notify.actionsGroup].onApply ?? removeNotify
  onApply(notify)
}

function onNotifyRemove(notify) {
  if (!invitations.value.contains(notify))
    return

  let onRemove = subscriptions?[notify.actionsGroup].onRemove
  onRemove?(notify)
  removeNotify(notify)
}

function clearAll() {
  let list = clone invitations.value
  foreach (notify in list) {
    let onRemove = subscriptions?[notify.actionsGroup].onRemove
    onRemove?(notify)
  }
  invitations(invitations.value.filter(@(n) !list.contains(n)))
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
  notify = NOTIFICATION_PARAMS.__merge({ time = serverTime.value }, notify)

  if (notify.id != null)
    removeNotifyById(notify.id)
  else {
    notify.id = $"_{counter.value}"
    counter(counter.value + 1)
  }

  invitations.mutate(@(v) v.append(notify))
}

function markReadAll() {
  if (hasUnread.value)
    invitations.mutate(@(v) v.each(@(notify) notify.isRead = true))
}

function markRead(id) {
  let idx = invitations.value.findindex(@(n) n.id == id)
  if (idx != null && !invitations.value[idx].isRead)
    invitations.mutate(@(v) v[idx] = v[idx].__merge({ isRead = true }))
}

isLoggedIn.subscribe(@(_) clearAll())
invitations.subscribe(@(v) v.len() > 0 ? null : isInvitationsOpened(false))

return {
  invitations
  hasUnread
  hasImportantUnread
  pushNotification
  removeNotifyById
  markReadAll
  markRead
  clearAll
  isInvitationsOpened

  openInvitations = @() isInvitationsOpened(true)
  subscribeGroup
  onNotifyRemove
  onNotifyApply
}
