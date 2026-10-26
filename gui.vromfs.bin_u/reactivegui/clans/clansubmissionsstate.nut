from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/pServerApi.nut" import clan_join_list, clan_complete_request, registerHandler,
  clanRequestsInProgress, clanRequestResponseInProgress
from "%appGlobals/permissions.nut" import allow_clans
from "%rGui/clans/clanPermissions.nut" import CLAN_JOIN_LIST, CLAN_COMPLETE_REQUEST, clanGrades, hasClanPermission
from "%rGui/clans/clanState.nut" import handleClanError
from "%rGui/clans/currentClanState.nut" import currentClanId, myClanGrade, JOIN_LIST_ID
from "%rGui/contacts/contact.nut" import validateNickNames


const COMPLETE_REQUEST_ID = "on_clan_complete_request"

let clanSubmissionsUids = mkWatched(persist, "clanSubmissionsUids", {})
let hasClanSubmissions = Computed(@() clanSubmissionsUids.get().len() > 0)
let submissionsClanId = keepref(Computed(function() {
  let clanId = currentClanId.get() ?? -1
  return allow_clans.get() && hasClanPermission(CLAN_JOIN_LIST, clanGrades.get(), myClanGrade.get()) ? clanId : -1
}))
let canCompleteClanRequest = keepref(Computed(@()
  hasClanPermission(CLAN_COMPLETE_REQUEST, clanGrades.get(), myClanGrade.get())))

function refreshClanSubmissions() {
  let clanId = submissionsClanId.get()
  if (clanId < 0 || clanRequestsInProgress.get())
    return
  clan_join_list(clanId, { id = JOIN_LIST_ID, clanId })
}

function completeClanRequest(clanId, userId, accept) {
  if (clanId == null || !canCompleteClanRequest.get() || userId in clanRequestResponseInProgress.get())
    return

  let requestorProjectId = clanSubmissionsUids.get()?[userId.tostring()].userProjectId
  clan_complete_request(clanId, accept, userId, requestorProjectId, { id = COMPLETE_REQUEST_ID, clanId, userId, accept })
}

let approveClanSubmission = @(userId) completeClanRequest(currentClanId.get(), userId.tointeger(), true)
let rejectClanSubmission = @(userId) completeClanRequest(currentClanId.get(), userId.tointeger(), false)

registerHandler(JOIN_LIST_ID, function(res, context) {
  if (handleClanError(res) || context.clanId != submissionsClanId.get())
    return

  let uids = {}
  foreach (user in (res?.users ?? []))
    if (user?.userId != null)
      uids[user.userId.tostring()] <- { userProjectId = user?.userProjectId, message = user?.message }

  clanSubmissionsUids.set(uids)
  validateNickNames(uids.keys())
})

registerHandler(COMPLETE_REQUEST_ID, function(res, context) {
  if (handleClanError(res) || context.clanId != submissionsClanId.get())
    return

  clanSubmissionsUids.mutate(@(v) v.$rawdelete(context.userId.tostring()))
})

function onSubmissionsClanId(clanId) {
  if (clanId >= 0)
    refreshClanSubmissions()
  else
    clanSubmissionsUids.set({})
}
onSubmissionsClanId(submissionsClanId.get())
submissionsClanId.subscribe(onSubmissionsClanId)

return {
  clanSubmissionsUids
  hasClanSubmissions
  clanRequestResponseInProgress
  canCompleteClanRequest
  approveClanSubmission
  rejectClanSubmission
}
