from "%globalsDarg/darg_library.nut" import *
let logP = log_with_prefix("[PUBLIC_INFO] ")
let { get_time_msec } = require("dagor.time")
let { deferOnce } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { contactsRequest, contactsRegisterHandler, canRequestToContacts } = require("contactsState.nut")

let AGEING_TIME_MSEC = 600000
let allPublicInfo = hardPersistWatched("allPublicInfo", {})
let delayedUids = mkWatched(persist, "delayedUids", {})
let inProgressUids = Watched({})
let needRequest = Computed(@() canRequestToContacts.value && delayedUids.value.len() > 0 && inProgressUids.value.len() == 0)

contactsRegisterHandler("get_public_users_info", function(result, context) {
  let { uids } = context
  inProgressUids(inProgressUids.value.filter(@(_, v) v not in uids))
  if (!(result?.success ?? true))
    return
  let upd = {}
  let timeUpd = { receiveTime = get_time_msec() }
  foreach(uid, _ in uids)
    upd[uid] <- (result?[uid] ?? {}).__merge(timeUpd)
  if (upd.len() != 0)
    allPublicInfo(allPublicInfo.value.__merge(upd))
})

function requestPublicInfo() {
  if (!needRequest.value)
    return

  let uids = delayedUids.value
  delayedUids({})
  logP($"Request public info for {uids.len()} contacts")
  inProgressUids(uids)
  contactsRequest("get_public_users_info",
    { data = { users = uids.keys(), tags = ["general"] } },
    { uids })
}

needRequest.subscribe(@(v) v ? deferOnce(requestPublicInfo) : null)
if (needRequest.value)
  requestPublicInfo()

let isNeedUpdate = @(info) info == null
  || info.receiveTime + AGEING_TIME_MSEC <= get_time_msec()

function refreshPublicInfo(uid) {
  if (isNeedUpdate(allPublicInfo.value?[uid])
      && uid not in inProgressUids.value
      && uid not in delayedUids.value)
    delayedUids.mutate(@(v) v[uid] <- true)
}

let mkPublicInfo = @(userId)
  Computed(@() allPublicInfo.value?[userId].general)

let mkIsPublicInfoWait = @(userId)
  Computed(@() userId in inProgressUids.get() )

return {
  allPublicInfo
  inProgressPublicInfo = inProgressUids
  mkIsPublicInfoWait
  refreshPublicInfo
  mkPublicInfo
}