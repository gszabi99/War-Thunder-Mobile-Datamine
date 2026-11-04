from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/pServerApi.nut" import clan_join_list, clan_complete_request, registerHandler,
  clanRequestsInProgress, clanRequestResponseInProgress, clan_reject_all_requests
from "%appGlobals/permissions.nut" import allow_clans
from "%rGui/clans/clanPermissions.nut" import CLAN_JOIN_LIST, CLAN_COMPLETE_REQUEST, clanGrades, hasClanPermission
from "%rGui/clans/clanState.nut" import handleClanError
from "%rGui/clans/currentClanState.nut" import currentClanId, myClanGrade, JOIN_LIST_ID, NO_CLAN_ID, currentClan,
  forceRefreshCurrentClan
from "%rGui/contacts/contact.nut" import validateNickNames


const COMPLETE_REQUEST_ID = "on_clan_complete_request"

let clanSubmissions = mkWatched(persist, "clanSubmissions", [])
let isAllApproveInProgress = mkWatched(persist, "isAllApproveInProgress", false)
let hasClanSubmissions = Computed(@() clanSubmissions.get().len() > 0)
let submissionsClanId = keepref(Computed(function() {
  let clanId = currentClanId.get() ?? NO_CLAN_ID
  return allow_clans.get() && hasClanPermission(CLAN_JOIN_LIST, clanGrades.get(), myClanGrade.get()) ? clanId : NO_CLAN_ID
}))
let canCompleteClanRequest = keepref(Computed(@()
  hasClanPermission(CLAN_COMPLETE_REQUEST, clanGrades.get(), myClanGrade.get())))
let isAllSubmissionsInProgress = Computed(@() isAllApproveInProgress.get() || -1 in clanRequestResponseInProgress.get())

isLoggedIn.subscribe(@(_) isAllApproveInProgress.set(false))

function refreshClanSubmissions() {
  let clanId = submissionsClanId.get()
  if (clanId < 0 || clanRequestsInProgress.get())
    return
  clan_join_list(clanId, { id = JOIN_LIST_ID, clanId })
}

function completeClanRequest(clanId, userId, accept) {
  if (clanId == NO_CLAN_ID || !canCompleteClanRequest.get() || userId in clanRequestResponseInProgress.get()
      || isAllSubmissionsInProgress.get())
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

function rejectAllClanSubmissions() {
  if (currentClanId.get() == NO_CLAN_ID || clanRequestResponseInProgress.get().len() != 0
      || isAllSubmissionsInProgress.get())
    return
  clan_reject_all_requests(currentClanId.get(), { id = "onRejectAllSubmissions", clanId = currentClanId.get() })
}

registerHandler("onRejectAllSubmissions", function(res, context) {
  if (handleClanError(res) || context.clanId != currentClanId.get())
    return
  clanSubmissions.set([])
  refreshClanSubmissions()
})

function requestNextSubmissionApprove(submissionQueue, needRejectOther) {
  if (submissionQueue.len() == 0) {
    if (needRejectOther)
      rejectAllClanSubmissions()
    else
      refreshClanSubmissions()
    forceRefreshCurrentClan()
    return
  }

  let newSubmissionQueue = clone submissionQueue
  let { userId, userProjectId } = newSubmissionQueue.remove(0)
  if (null == clanSubmissions.get().findvalue(@(v) v.userId == userId))
    return

  isAllApproveInProgress.set(true)
  clan_complete_request(submissionsClanId.get(), true, userId, userProjectId,
    { id = "onSubmissionQueueApprove", clanId = submissionsClanId.get(), userId,
      submissionQueue = newSubmissionQueue, needRejectOther
    })
}

registerHandler("onSubmissionQueueApprove", function(res, context) {
  isAllApproveInProgress.set(false)
  if (handleClanError(res) || context.clanId != submissionsClanId.get())
    return
  let { userId, submissionQueue, needRejectOther } = context
  let idx = clanSubmissions.get().findindex(@(v) v.userId == userId)
  if (idx != null)
    clanSubmissions.mutate(@(v) v.remove(idx))
  requestNextSubmissionApprove(submissionQueue, needRejectOther)
})

function approveAllClanSubmissions() {
  if (submissionsClanId.get() == NO_CLAN_ID || clanSubmissions.get().len() == 0
      || clanRequestResponseInProgress.get().len() != 0 || isAllSubmissionsInProgress.get())
    return
  let freeSlots = (currentClan.get()?.maxMembers ?? 0) - (currentClan.get()?.users.len() ?? 0)
  if (freeSlots <= 0)
    return

  let submissionQueue = (clone clanSubmissions.get()).slice(0, freeSlots)
  requestNextSubmissionApprove(submissionQueue, freeSlots < clanSubmissions.get().len())
}

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
  canCompleteClanRequest
  approveClanSubmission
  rejectClanSubmission
  rejectAllClanSubmissions
  approveAllClanSubmissions
  isAllSubmissionsInProgress
}
