from "%globalsDarg/darg_library.nut" import *
let utf8 = require("utf8")
let { getLocalLanguage } = require("language")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { contactsRequest, contactsRegisterHandler } = require("%rGui/contacts/contactsClient.nut")
let { battleSessionId, isInBattle, isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { Contact } = require("%rGui/contacts/contact.nut")

let session = Computed(@() (isInBattle.get() || isInDebriefing.get()) ? battleSessionId.get() : -1)

let langCfg = {
  English = { locale = "en-US", lang = "english" }
  Russian = { locale = "ru-RU", lang = "russian" }
}

let MAX_MESSAGE_CHARS = 256

let SUCCESS_WND_UID = "successReportWindow"
let REPORT_WND_UID = "playerReportWindow"

let categoryCfg = ["OTHER", "CHEAT", "ABUSE"].map(@(v) loc($"support/form/report/{v}"))

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
  contactsRequest("cln_complaint_v2", { data = request }, request)
}

contactsRegisterHandler("cln_complaint_v2", function(result, request) {
  isRequestInProgress.set(false)
  if (!result?.error)
    return isReportStatusSuccessed.set(true)

  log("cln_complaint_v2 result = ", result)
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
  viewReport = @(userId) selectedPlayerForReport.set({
    offender_userid = userId
    offender_nick = Contact(userId).get()?.realnick ?? ""
    room_id = session.get()
  })
}
