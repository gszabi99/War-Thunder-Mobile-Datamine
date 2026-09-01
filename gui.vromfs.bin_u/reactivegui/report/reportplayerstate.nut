from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_send
from "language" import getLocalLanguage
import "utf8" as utf8
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/clientState/clientState.nut" import battleSessionId, isInBattle, isInDebriefing
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/modalWindows.nut" import removeModalWindow
from "%rGui/contacts/contact.nut" import Contact
from "%rGui/contacts/contactsClient.nut" import contactsRequest, contactsRegisterHandler
from "%rGui/debriefing/debriefingState.nut" import debriefingData


let session = Computed(@() (isInBattle.get() || isInDebriefing.get()) ? battleSessionId.get() : -1)

let langCfg = {
  English = { locale = "en-US", lang = "english" }
  Russian = { locale = "ru-RU", lang = "russian" }
}

const MAX_ACTIVE_REPORTS = 5
const MAX_REPORTS_IN_SESSION = 15
const TIME_TO_NEXT_BATTLE_REPORT = 30 * 60
const TIME_TO_NEXT_MENU_REPORT = 12 * 3600
const TIME_TO_NEXT_REPORT_BAN = 48 * 3600
const SHADOW_REPORT_BAN_TIME = "shadowReportBanTime"
const BATTLE_REPORT = "battleReport"
const MENU_REPORT = "menuReport"

const MAX_MESSAGE_CHARS = 256

const SUCCESS_WND_UID = "successReportWindow"
const REPORT_WND_UID = "playerReportWindow"
const REJECT_WND_UID = "rejectReportWindow"

let categoryCfg = ["OTHER", "CHEAT", "TEAMKILL", "SKIN"]

let selectedPlayerForReport = Watched(null)
let isReportStatusSuccessed = Watched(false)
let isReportStatusRejected = Watched(false)
let isRequestInProgress = Watched(false)
let fieldCategory = hardPersistWatched("fieldReportCategory", "")
let fieldMessage = hardPersistWatched("fieldReportMessage", "")
let countReportsPerSession = hardPersistWatched("countReportsPerSession", 0)

let hasShadowBan = Computed(@()
  (TIME_TO_NEXT_REPORT_BAN - (serverTime.get() - (get_local_custom_settings_blk()?[SHADOW_REPORT_BAN_TIME] ?? 0))) > 0)

selectedPlayerForReport.subscribe(function(_) {
  isRequestInProgress.set(false)
  isReportStatusSuccessed.set(false)
  isReportStatusRejected.set(false)
  removeModalWindow(SUCCESS_WND_UID)
  removeModalWindow(REJECT_WND_UID)
})

function resetForm() {
  foreach (field in [ fieldCategory, fieldMessage ])
    field.set("")
}

function close() {
  selectedPlayerForReport.set(null)
  deferOnce(resetForm)
}

function getFormValidationError() {
  let err = []
  if (fieldCategory.get() == "")
    err.append(loc("support/form/hint/select_a_category"))
  if (fieldMessage.get() == "")
    err.append(loc("support/form/hint/fill_all_text_fields"))
  if (utf8(fieldMessage.get()).charCount() > MAX_MESSAGE_CHARS)
    err.append(loc("support/form/hint/support/form/hint/max_number_of_characters"))
  return "\n".join(err)
}

function getMaxActiveReportTime(userIdStr) {
  let blk = get_local_custom_settings_blk()?[MENU_REPORT]
  if (!blk)
    return 0

  if(blk.paramCount() < MAX_ACTIVE_REPORTS)
    return blk?[userIdStr] ?? 0

  local minTime = 0
  for (local idx = blk.paramCount() - 1; idx >= 0; idx--)
    if (blk.getParamValue(idx) < minTime || minTime == 0)
      minTime = blk.getParamValue(idx)
  return minTime
}

function clearExpiredReports(reportType, currentTime) {
  let blk = get_local_custom_settings_blk()?[reportType]
  if (!blk)
    return

  for (local idx = blk.paramCount() - 1; idx >= 0; idx--)
    if (currentTime - blk.getParamValue(idx) >= TIME_TO_NEXT_MENU_REPORT)
      blk.removeParam(blk.getParamName(idx))
}

let mkTimeToNextReport = @(userIdStr) isInBattle.get() || userIdStr in debriefingData.get()?.players
  ? Computed(@() TIME_TO_NEXT_BATTLE_REPORT - (serverTime.get()
    - (get_local_custom_settings_blk()?[BATTLE_REPORT][userIdStr] ?? 0)))
  : Computed(@() TIME_TO_NEXT_MENU_REPORT - (serverTime.get() - getMaxActiveReportTime(userIdStr)))

function saveComplaint(request) {
  let blk = get_local_custom_settings_blk()
  let userIdStr = request.offender_userid

  foreach (reportType in [BATTLE_REPORT, MENU_REPORT])
    if (blk?[reportType])
      clearExpiredReports(reportType, serverTime.get())

  blk.addBlock(
    (isInBattle.get() || userIdStr in debriefingData.get()?.players)
      ? BATTLE_REPORT
      : MENU_REPORT)[userIdStr] = request.date

  eventbus_send("saveProfile", {})
}

function applyShadowBan() {
  let blk = get_local_custom_settings_blk()
  blk[SHADOW_REPORT_BAN_TIME] = serverTime.get()

  saveComplaint({
    offender_userid = selectedPlayerForReport.get()?.offender_userid ?? ""
    date = serverTime.get()
  })
  isReportStatusSuccessed.set(true)
}

function mkRequest(requestData) {
  if (requestData == null)
    return null

  let { lang } = langCfg?[getLocalLanguage()] ?? langCfg.English
  let res = clone requestData
  res.category <- utf8ToUpper(fieldCategory.get())
  res.user_comment <- fieldMessage.get()
  res.date <- serverTime.get()
  res.lang <- lang
  return res
}

function requestSelfRow() {
  let requestData = selectedPlayerForReport.get()
  if (!requestData)
    return

  if (hasShadowBan.get()) {
    saveComplaint({
      offender_userid = requestData.offender_userid
      date = serverTime.get()
    })
    isReportStatusSuccessed.set(true)
    return
  }

  if (countReportsPerSession.get() >= MAX_REPORTS_IN_SESSION)
    return applyShadowBan()

  let timeToNextReport = mkTimeToNextReport(requestData.offender_userid).get()
  if (!(timeToNextReport <= 0))
    return isReportStatusRejected.set(true)

  countReportsPerSession.set(countReportsPerSession.get() + 1)

  let request = mkRequest(requestData)
  isRequestInProgress.set(true)
  contactsRequest("cln_complaint", { data = request }, request)
}

contactsRegisterHandler("cln_complaint", function(result, request) {
  isRequestInProgress.set(false)
  if (!result?.error) {
    saveComplaint(request)
    return isReportStatusSuccessed.set(true)
  }

  log("cln_complaint result = ", result)
  logerr($"Failed to send report: {request}")
})

return {
  SUCCESS_WND_UID
  REJECT_WND_UID
  REPORT_WND_UID
  MAX_MESSAGE_CHARS
  categoryCfg
  fieldCategory
  fieldMessage
  close
  getFormValidationError
  selectedPlayerForReport
  requestSelfRow
  isReportStatusSuccessed
  isReportStatusRejected
  isRequestInProgress
  mkTimeToNextReport
  viewReport = @(userIdStr) selectedPlayerForReport.set({
    offender_userid = userIdStr
    offender_nick = Contact(userIdStr).get()?.realnick ?? ""
    room_id = session.get()
  })
}
