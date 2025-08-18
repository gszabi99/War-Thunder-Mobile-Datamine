from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { getLocalLanguage } = require("language")
let { utf8ToUpper, validateEmail } = require("%sqstd/string.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { myUserIdStr, myUserName } = require("%appGlobals/profileStates.nut")
let { sendErrorBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { textButtonPrimary, textButtonCommon, buttonsHGap } = require("%rGui/components/textButton.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { horizontalToggleWithLabel } = require("%rGui/components/toggle.nut")
let { canUseZendeskApi, langCfg, getCategoryLocName, fieldCategory } = require("%rGui/feedback/supportState.nut")
let { hasLogFile } = require("%rGui/feedback/logFileAttachment.nut")
let { requestState, submitSupportRequest, onRequestResultSeen } = require("%rGui/feedback/supportRequest.nut")
let supportChooseCategory = require("%rGui/feedback/supportChooseCategory.nut")

let isOpened = mkWatched(persist, "isOpened", false)
let onClose = @() isOpened.set(false)

let fieldEmail = hardPersistWatched("fieldEmail", "")
let fieldSubject = hardPersistWatched("fieldSubject", "")
let fieldMessage = hardPersistWatched("fieldMessage", "")
let tglNeedAttachLogFile = hardPersistWatched("tglNeedAttachLogFile", false)

function resetForm() {
  foreach (field in [ fieldEmail, fieldCategory, fieldSubject, fieldMessage ])
    field.set("")
  tglNeedAttachLogFile.set(false)
}

function getFormValidationError() {
  let err = []
  if (fieldCategory.value == "")
    err.append(loc("support/form/hint/select_a_category"))
  foreach (field in [ fieldEmail, fieldSubject, fieldMessage ])
    if (field.value == "") {
      err.append(loc("support/form/hint/fill_all_text_fields"))
      break
    }
  if (fieldEmail.get() != "" && !validateEmail(fieldEmail.get()))
    err.append(loc("support/form/hint/enter_valid_email"))
  return "\n".join(err)
}

function submitImpl() {
  let { locale, lang } = langCfg?[getLocalLanguage()] ?? langCfg.English
  submitSupportRequest({
    email = fieldEmail.get()
    userId = myUserIdStr.get()
    name = myUserName.get()
    category = fieldCategory.get()
    subject = fieldSubject.get()
    message = fieldMessage.get()
    locale
    lang
    needAttachLogFile = tglNeedAttachLogFile.get()
  })
}

function onSubmit() {
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
  size = FLEX_H
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
    touchMarginPriority = TOUCH_BACKGROUND
    skipDirPadNav = true
    children = content
  }
}.__update(override)

function categoryComp() {
  let text = fieldCategory.get() == ""
    ? loc("support/form/hint/select_a_category")
    : "".concat(loc("support/form/category"), colon, getCategoryLocName(fieldCategory.get()))
  return {
    watch = fieldCategory
    size = FLEX_H
    children = textButtonCommon(text, supportChooseCategory)
  }
}

let mkTextInputField = @(textWatch, placeholderText, options = {}) textInput(textWatch, {
  placeholder = placeholderText
  onChange = @(value) textWatch(value)
  onEscape = @() textWatch("")
}.__update(options))

let formBlock = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = hdpx(25)
  children = [
    categoryComp
    mkTextInputField(fieldSubject, loc("support/form/subject"), { maxChars = 150 })
    mkTextInputField(fieldMessage, loc("support/form/message"), { maxChars = 2048 })
    mkTextInputField(fieldEmail, loc("support/form/your_email"), { maxChars = 80, inputType = "mail" })
    {
      size = FLEX_H
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = buttonsHGap
      children = [
        {
          size = FLEX_H
          children = hasLogFile()
            ? horizontalToggleWithLabel(tglNeedAttachLogFile, loc("support/form/log_file_attachment/checkbox"))
            : null
        }
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

function mkFinishedMsg(reqStateVal) {
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
  size = FLEX_H
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
      children = requestState.get()?.id != null ? mkFinishedMsg(requestState.get())
        : requestState.get().isProcessing ? waitBlock
        : mkVerticalPannableArea(formBlock, { size = flex() })
    }
  ]
  animations = wndSwitchAnim
})

isLoggedIn.subscribe(@(v) v ? null : resetForm())
isOpened.subscribe(@(v) !v && requestState.get().id != null
  ? onRequestResultSeen()
  : null)

requestState.subscribe(function(v) {
  if (v.id != null) 
    resetForm()
  else if (v.errInfo != null) {
    let { errId, errText, needSendBQ } = v.errInfo
    if (needSendBQ)
      sendErrorBqEvent($"Zendesk: {errId}")
    openMsgBox({ text = errText })
  }
})

registerScene("supportWnd", supportWnd, onClose, isOpened)

let openSupportTicketWnd = @() isOpened.set(true)
let openSupportTicketUrl = @() eventbus_send("openUrl", { baseUrl = loc("url/feedback/support") })
let openSupportTicketWndOrUrl = @() canUseZendeskApi.get() ? openSupportTicketWnd() : openSupportTicketUrl()

return {
  openSupportTicketWndOrUrl
}
