from "%globalsDarg/darg_library.nut" import *
let { getLocalLanguage } = require("language")
let { utf8ToUpper, validateEmail } = require("%sqstd/string.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { sendErrorBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { OCT_LIST } = require("%rGui/options/optCtrlType.nut")
let mkOption = require("%rGui/options/mkOption.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { textButtonPrimary, buttonsHGap } = require("%rGui/components/textButton.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let backButton = require("%rGui/components/backButton.nut")
let { hasLogFile } = require("logFileAttachment.nut")
let { requestState, submitSupportRequest, onRequestResultSeen } = require("supportRequest.nut")

let langCfg = {
  English = { locale = "en-US", lang = "english" }
  Russian = { locale = "ru-RU", lang = "russian" }
}
let categoryCfg = [
  { id = "gameplay",  zenId = "\u0438\u0433\u0440\u043e\u0432\u043e\u0439_\u043f\u0440\u043e\u0446\u0435\u0441\u0441_\u043c\u043e\u0431" }
  { id = "financial", zenId = "\u0444\u0438\u043d\u0430\u043d\u0441\u043e\u0432\u044b\u0435_\u0432\u043e\u043f\u0440\u043e\u0441\u044b_\u043c\u043e\u0431" }
  { id = "personal",  zenId = "\u043f\u0435\u0440\u0441\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0435_\u0434\u0430\u043d\u043d\u044b\u0435_\u043c\u043e\u0431" }
]

let isOpened = mkWatched(persist, "isOpened", false)
let onClose = @() isOpened(false)

let fieldEmail = hardPersistWatched("fieldEmail", "")
let fieldName = hardPersistWatched("fieldName", "")
let fieldCategory = hardPersistWatched("fieldCategory", "")
let fieldSubject = hardPersistWatched("fieldSubject", "")
let fieldMessage = hardPersistWatched("fieldMessage", "")

let function resetForm() {
  foreach (field in [ fieldEmail, fieldName, fieldCategory, fieldSubject, fieldMessage ])
    field("")
}

let function getFormValidationError() {
  let err = []
  if (fieldCategory.value == "")
    err.append(loc("support/form/hint/select_a_category"))
  foreach (field in [ fieldEmail, fieldName, fieldSubject, fieldMessage ])
    if (field.value == "") {
      err.append(loc("support/form/hint/fill_all_text_fields"))
      break
    }
  if (fieldEmail.value != "" && !validateEmail(fieldEmail.value))
    err.append(loc("support/form/hint/enter_valid_email"))
  return "\n".join(err)
}

let function submitImpl() {
  let { locale, lang } = langCfg?[getLocalLanguage()] ?? langCfg.English
  submitSupportRequest({
    email = fieldEmail.value
    name = fieldName.value
    category = categoryCfg.findvalue(@(v) v.id == fieldCategory.value)?.zenId ?? ""
    subject = fieldSubject.value
    message = fieldMessage.value
    locale
    lang
  })
}

let function onSubmit() {
  let errorText = getFormValidationError()
  if (errorText != "")
    return openMsgBox({ text = errorText })

  openMsgBox({
    text = loc("support/form/submit_comfirm_question")
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "submit", styleId = "PRIMARY", cb = submitImpl }
    ]
  })
}

let txtBase = {
  rendObj = ROBJ_TEXT
  size = SIZE_TO_CONTENT
  color = 0xFFFFFFFF
}.__merge(fontSmall)

let txt = @(ovr) txtBase.__merge(ovr)

let txtArea = @(ovr) txtBase.__merge({
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
}, ovr)

let mkVerticalPannableArea = @(content, override) {
  size = flex()
  flow = FLOW_VERTICAL
  clipChildren = true
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    skipDirPadNav = true
    children = content
  }
}.__update(override)

let mkTextInputField = @(textWatch, placeholderText, options = {}) textInput(textWatch, {
  placeholder = placeholderText
  onChange = @(value) textWatch(value)
  onEscape = @() textWatch("")
}.__update(options))

let optCategory = {
  locId = "support/form/category"
  ctrlType = OCT_LIST
  value = fieldCategory
  list = Watched(categoryCfg.map(@(v) v.id))
  valToString = @(id) loc($"support/form/category/{id}")
}

let formBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(25)
  children = [
    mkOption(optCategory)
    mkTextInputField(fieldName, loc("support/form/your_name"), { maxChars = 80 })
    mkTextInputField(fieldSubject, loc("support/form/subject"), { maxChars = 150 })
    mkTextInputField(fieldMessage, loc("support/form/message"), { maxChars = 2048 })
    mkTextInputField(fieldEmail, loc("support/form/your_email"), { maxChars = 80, inputType = "mail" })
    {
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = buttonsHGap
      children = [
        hasLogFile()
          ? txtArea({ text = loc("support/form/log_file_attachment") })
          : null
        textButtonPrimary(utf8ToUpper(loc("msgbox/btn_submit")), onSubmit)
      ]
    }
  ]
}

let waitBlock = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  children = [
    mkSpinner(evenPx(100))
    txt({ text = loc("msgbox/please_wait") })
  ]
}

let function mkFinishedMsg(reqStateVal) {
  let emailAddress = reqStateVal.formData.email
  let requestId = reqStateVal.id
  return txtArea({
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    text = "\n".concat(
      loc("support/form/result/created"),
      loc("support/form/result/contact", { emailAddress }),
      loc("support/form/result/id", { requestId })
    )
  }.__update(fontMedium))
}

let header = {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  children = [
    backButton(onClose)
    {
      hplace = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = 0xFFFFFFFF
      text = loc("support/form/title")
    }.__update(fontBig)
  ]
}

let supportWnd = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    header
    @() {
      watch = requestState
      size = flex()
      children = requestState.value?.id != null ? mkFinishedMsg(requestState.value)
        : requestState.value.isProcessing ? waitBlock
        : mkVerticalPannableArea(formBlock, { size = flex() })
    }
  ]
  animations = wndSwitchAnim
})

isLoggedIn.subscribe(@(v) v ? null : resetForm())
isOpened.subscribe(@(v) !v && requestState.value.id != null
  ? onRequestResultSeen()
  : null)

requestState.subscribe(function(v) {
  if (v.id != null) // Success
    resetForm()
  else if (v.errInfo != null) {
    let { errId, errText } = v.errInfo
    sendErrorBqEvent($"Zendesk: {errId}")
    openMsgBox({ text = "\n".concat(
      "".concat(loc("msgbox/appearError"), colon),
      errText)
    })
  }
})

registerScene("supportWnd", supportWnd, onClose, isOpened)

return {
  openSupportWnd = @() isOpened(true)
}
