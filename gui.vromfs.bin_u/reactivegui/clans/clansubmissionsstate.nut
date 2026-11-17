from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send
from "json" import object_to_json_string, parse_json
from "types" import String
from "%appGlobals/loginState.nut" import isLoggedIn, isOnlineSettingsAvailable
from "%appGlobals/pServer/pServerApi.nut" import clan_join_list, clan_complete_request, registerHandler,
  clanRequestsInProgress, clanRequestResponseInProgress, clan_reject_all_requests
from "%appGlobals/permissions.nut" import allow_clans
from "%rGui/account/resetProfileDetector.nut" import subscribeResetProfile
from "%rGui/clans/clanPermissions.nut" import CLAN_JOIN_LIST, CLAN_COMPLETE_REQUEST, clanGrades, hasClanPermission
from "%rGui/clans/clanState.nut" import handleClanError
from "%rGui/clans/currentClanState.nut" import currentClanId, myClanGrade, JOIN_LIST_ID, NO_CLAN_ID, currentClan,
  forceRefreshCurrentClan, isReadyToConnect
from "%rGui/contacts/contact.nut" import validateNickNames


const COMPLETE_REQUEST_ID = "on_clan_complete_request"
const SEEN_SAVE_ID = "seenClanSubmissions"

let clanSubmissions = mkWatched(persist, "clanSubmissions", [])
let clanSubmissionsClanId = mkWatched(persist, "clanSubmissionsClanId", NO_CLAN_ID)
let seenClanSubmissions = Watched({ clanId = NO_CLAN_ID, userIds = {} })
let isAllApproveInProgress = mkWatched(persist, "isAllApproveInProgress", false)
let hasClanSubmissions = Computed(@() clanSubmissions.get().len() > 0)
let hasUnseenClanSubmissions = Computed(@()
  null != clanSubmissions.get().findvalue(@(s) s.userId not in seenClanSubmissions.get().userIds))
let submissionsClanId = keepref(Computed(function() {
  let clanId = currentClanId.get() ?? NO_CLAN_ID
  return allow_clans.get() && hasClanPermission(CLAN_JOIN_LIST, clanGrades.get(), myClanGrade.get()) ? clanId : NO_CLAN_ID
}))
let canCompleteClanRequest = keepref(Computed(@()
  hasClanPermission(CLAN_COMPLETE_REQUEST, clanGrades.get(), myClanGrade.get())))
let isAllSubmissionsInProgress = Computed(@() isAllApproveInProgress.get() || -1 in clanRequestResponseInProgress.get())

isLoggedIn.subscribe(@(_) isAllApproveInProgress.set(false))

function loadSeenClanSubmissions() {
  let seenStr = isOnlineSettingsAvailable.get() ? get_local_custom_settings_blk()?[SEEN_SAVE_ID] : null
  local seen = {}
  if (seenStr instanceof String && seenStr != "") {
    try {
      seen = parse_json(seenStr)
    }
    catch(_) {
      logerr("Failed to load seen clan submissions")
    }
  }
  let { clanId = NO_CLAN_ID, userIds = [] } = seen
  seenClanSubmissions.set({ clanId, userIds = userIds.reduce(@(res, id) res.$rawset(id, true), {}) })
}

function saveSeenClanSubmissions(clanId, userIds) {
  seenClanSubmissions.set({ clanId, userIds })
  if (!isOnlineSettingsAvailable.get())
    return
  get_local_custom_settings_blk()[SEEN_SAVE_ID] = object_to_json_string({ clanId, userIds = userIds.keys() })
  eventbus_send("saveProfile", {})
}

subscribeResetProfile(@() saveSeenClanSubmissions(NO_CLAN_ID, {}))

function markClanSubmissionsSeen() {
  if (!hasUnseenClanSubmissions.get())
    return
  saveSeenClanSubmissions(clanSubmissionsClanId.get(),
    clanSubmissions.get().reduce(@(res, s) res.$rawset(s.userId, true), {}))
}

function removeOutdatedSeenSubmissions(clanId) {
  if (!isOnlineSettingsAvailable.get())
    return
  let seen = seenClanSubmissions.get()
  let userIds = seen.clanId == clanId ? seen.userIds : {}
  let actual = clanSubmissions.get().reduce(@(res, s) s.userId in userIds ? res.$rawset(s.userId, true) : res, {})
  if (clanId != seen.clanId || actual.len() != userIds.len())
    saveSeenClanSubmissions(clanId, actual)
}

function initSeenClanSubmissions() {
  loadSeenClanSubmissions()
  let clanId = clanSubmissionsClanId.get()
  if (clanId != NO_CLAN_ID && clanId == submissionsClanId.get())
    removeOutdatedSeenSubmissions(clanId)
}

initSeenClanSubmissions()
isOnlineSettingsAvailable.subscribe(@(_) initSeenClanSubmissions())

function removeClanSubmission(clanId, userId) {
  let idx = clanSubmissions.get().findindex(@(v) v.userId == userId)
  if (idx != null)
    clanSubmissions.mutate(@(v) v.remove(idx))
  removeOutdatedSeenSubmissions(clanId)
}

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
  clanSubmissionsClanId.set(context.clanId)
  removeOutdatedSeenSubmissions(context.clanId)
  validateNickNames(submissions.map(@(s) s.userId.tostring()))
})

registerHandler(COMPLETE_REQUEST_ID, function(res, context) {
  if (handleClanError(res) || context.clanId != submissionsClanId.get())
    return
  removeClanSubmission(context.clanId, context.userId)
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
  removeOutdatedSeenSubmissions(context.clanId)
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
  let { clanId, userId, submissionQueue, needRejectOther } = context
  removeClanSubmission(clanId, userId)
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
  else {
    clanSubmissions.set([])
    clanSubmissionsClanId.set(NO_CLAN_ID)
  }
}
onSubmissionsClanId(submissionsClanId.get())
submissionsClanId.subscribe(onSubmissionsClanId)

currentClanId.subscribe(@(clanId) clanId == NO_CLAN_ID && isReadyToConnect.get()
  ? removeOutdatedSeenSubmissions(NO_CLAN_ID)
  : null)

return {
  clanSubmissions
  hasClanSubmissions
  hasUnseenClanSubmissions
  markClanSubmissionsSeen
  canCompleteClanRequest
  approveClanSubmission
  rejectClanSubmission
  rejectAllClanSubmissions
  approveAllClanSubmissions
  isAllSubmissionsInProgress
}
