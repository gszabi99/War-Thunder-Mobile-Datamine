from "%globalsDarg/darg_library.nut" import *
let logP = log_with_prefix("[PUBLIC_INFO] ")
let { get_time_msec } = require("dagor.time")
let { deferOnce } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { contactsRequest, contactsRegisterHandler, canRequestToContacts } = require("%rGui/contacts/contactsState.nut")

let AGEING_TIME_MSEC = 600000
let maxUidInRequest = 100
let allPublicInfo = hardPersistWatched("allPublicInfo", {})
let delayedUids = mkWatched(persist, "delayedUids", {})
let inProgressUids = Watched({})
let needRequest = Computed(@() canRequestToContacts.get() && delayedUids.get().len() > 0 && inProgressUids.get().len() == 0)

function requestPublicInfo() {
  if (!needRequest.get())
    return

  let uids = delayedUids.get()
  local usersToSend = []
  local uidsToSend = {}
  if (uids.len() > maxUidInRequest) {
    usersToSend = uids.keys().slice(0, maxUidInRequest)
    uidsToSend = usersToSend.reduce(function(res, uid) {
      res[uid] <- true
      return res
    }, {})
    inProgressUids.set(uidsToSend)
    delayedUids.set(uids.filter(@(_, v) !uidsToSend?[v]))
  } else {
    usersToSend = uids.keys()
    inProgressUids.set(uids)
    delayedUids.set({})
    uidsToSend = uids
  }
  logP($"Request public info for {usersToSend.len()} contacts")
  contactsRequest("get_public_users_info",
    { data = { users = usersToSend, tags = ["general"] } },
    { uids = uidsToSend })
}

contactsRegisterHandler("get_public_users_info", function(result, context) {
  let { uids } = context
  inProgressUids.set(inProgressUids.get().filter(@(_, v) v not in uids))
  if (!(result?.success ?? true))
    return
  let upd = {}
  let timeUpd = { receiveTime = get_time_msec() }
  foreach(uid, _ in uids)
    upd[uid] <- (result?[uid] ?? {}).__merge(timeUpd)
  if (upd.len() != 0)
    allPublicInfo.set(allPublicInfo.get().__merge(upd))
  requestPublicInfo()
})

needRequest.subscribe(@(v) v ? deferOnce(requestPublicInfo) : null)
if (needRequest.get())
  requestPublicInfo()

let isNeedUpdate = @(info) info == null
  || info.receiveTime + AGEING_TIME_MSEC <= get_time_msec()

function refreshPublicInfo(uid) {
  if (isNeedUpdate(allPublicInfo.get()?[uid])
      && uid not in inProgressUids.get()
      && uid not in delayedUids.get())
    delayedUids.mutate(@(v) v[uid] <- true)
}

let mkPublicInfo = @(userId)
  Computed(@() allPublicInfo.get()?[userId].general)

let mkIsPublicInfoWait = @(userId)
  Computed(@() userId in inProgressUids.get() )

function deactualizePublicInfos(ids) {
  let updatedReceiveTime = {}
  foreach(uid in ids){
    local publicMemberInfo = allPublicInfo.get()?[uid.tostring()]
    if (publicMemberInfo)
      updatedReceiveTime[uid.tostring()] <- publicMemberInfo.__merge({receiveTime = publicMemberInfo.receiveTime - AGEING_TIME_MSEC})
  }

  if (updatedReceiveTime.len() > 0)
    allPublicInfo.set(allPublicInfo.get().__merge(updatedReceiveTime))
}

return {
  allPublicInfo
  inProgressPublicInfo = inProgressUids
  mkIsPublicInfoWait
  refreshPublicInfo
  mkPublicInfo
  deactualizePublicInfos
}