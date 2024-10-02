from "%globalsDarg/darg_library.nut" import *
let utf8 = require("utf8")
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { getLocalLanguage } = require("language")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { contactsRequest, contactsRegisterHandler } = require("%rGui/contacts/contactsClient.nut")
let { battleSessionId, isInBattle, isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { Contact } = require("%rGui/contacts/contact.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")

let session = Computed(@() (isInBattle.get() || isInDebriefing.get()) ? battleSessionId.get() : -1)

let langCfg = {
  English = { locale = "en-US", lang = "english" }
  Russian = { locale = "ru-RU", lang = "russian" }
}

let MAX_ACTIVE_REPORTS = 5
let TIME_TO_NEXT_BATTLE_REPORT = 30 * 60
let TIME_TO_NEXT_MENU_REPORT = 12 * 3600
let BATTLE_REPORT = "battleReport"
let MENU_REPORT = "menuReport"

let MAX_MESSAGE_CHARS = 256

let SUCCESS_WND_UID = "successReportWindow"
let REPORT_WND_UID = "playerReportWindow"

let categoryCfg = ["OTHER", "CHEAT", "TEAMKILL"]

let selectedPlayerForReport = Watched(null)
let isReportStatusSuccessed = Watched(false)
let isRequestInProgress = Watched(false)
let fieldCategory = hardPersistWatched("fieldReportCategory", "")
let fieldMessage = hardPersistWatched("fieldReportMessage", "")

function close() {
  selectedPlayerForReport(null)
  isRequestInProgress.set(false)
}

function resetForm() {
  foreach (field in [ fieldCategory, fieldMessage ])
    field("")
}

function cancel() {
  resetForm()
  close()
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

function successedClose() {
  isReportStatusSuccessed.set(false)
  removeModalWindow(SUCCESS_WND_UID)
  resetForm()
  close()
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
  REPORT_WND_UID
  MAX_MESSAGE_CHARS
  categoryCfg
  fieldCategory
  fieldMessage
  cancel
  successedClose
  getFormValidationError
  selectedPlayerForReport
  requestSelfRow
  isReportStatusSuccessed
  isRequestInProgress
  mkTimeToNextReport
  viewReport = @(userIdStr) selectedPlayerForReport.set({
    offender_userid = userIdStr
    offender_nick = Contact(userIdStr).get()?.realnick ?? ""
    room_id = session.get()
  })
}
