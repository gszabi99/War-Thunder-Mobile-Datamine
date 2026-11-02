from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/pServerApi.nut" import clan_join_list, clan_complete_request, registerHandler,
  clanRequestsInProgress, clanRequestResponseInProgress
from "%appGlobals/permissions.nut" import allow_clans
from "%rGui/clans/clanPermissions.nut" import CLAN_JOIN_LIST, CLAN_COMPLETE_REQUEST, clanGrades, hasClanPermission
from "%rGui/clans/clanState.nut" import handleClanError
from "%rGui/clans/currentClanState.nut" import currentClanId, myClanGrade, JOIN_LIST_ID
from "%rGui/contacts/contact.nut" import validateNickNames


const COMPLETE_REQUEST_ID = "on_clan_complete_request"

let clanSubmissions = mkWatched(persist, "clanSubmissions", [])
let hasClanSubmissions = Computed(@() clanSubmissions.get().len() > 0)
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
  let { userProjectId = null } = clanSubmissions.get().findvalue(@(v) v.userId == userId)
  if (userProjectId == null)
    return
  clan_complete_request(clanId, accept, userId, userProjectId, { id = COMPLETE_REQUEST_ID, clanId, userId, accept })
}

let approveClanSubmission = @(userId) completeClanRequest(currentClanId.get(), userId, true)
let rejectClanSubmission = @(userId) completeClanRequest(currentClanId.get(), userId, false)

registerHandler(JOIN_LIST_ID, function(res, context) {
  if (handleClanError(res) || context.clanId != submissionsClanId.get())
    return

  let submissions = (res?.users ?? []).filter(@(v) "userId" in v && "userProjectId" in v)
  clanSubmissions.set(submissions)
  validateNickNames(submissions.map(@(s) s.userId.tostring()))
})

registerHandler(COMPLETE_REQUEST_ID, function(res, context) {
  if (handleClanError(res) || context.clanId != submissionsClanId.get())
    return
  let { userId } = context
  let idx = clanSubmissions.get().findindex(@(v) v.userId == userId)
  if (idx != null)
    clanSubmissions.mutate(@(v) v.remove(idx))
})

function onSubmissionsClanId(clanId) {
  if (clanId >= 0)
    refreshClanSubmissions()
  else
    clanSubmissions.set([])
}
onSubmissionsClanId(submissionsClanId.get())
submissionsClanId.subscribe(onSubmissionsClanId)

return {
  clanSubmissions
  hasClanSubmissions
  clanRequestResponseInProgress
  canCompleteClanRequest
  approveClanSubmission
  rejectClanSubmission
}
