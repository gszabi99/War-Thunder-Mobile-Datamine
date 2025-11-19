from "%globalsDarg/darg_library.nut" import *
let utf8 = require("utf8")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { dropDownMenu } = require("%rGui/components/dropDownMenu.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { REJECT_WND_UID, SUCCESS_WND_UID, REPORT_WND_UID, categoryCfg, fieldCategory, fieldMessage,
  getFormValidationError, selectedPlayerForReport, requestSelfRow, close,
  isReportStatusSuccessed, isReportStatusRejected, MAX_MESSAGE_CHARS, isRequestInProgress } = require("%rGui/report/reportPlayerState.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { btnBUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let defColor = 0xFFFFFFFF
let componentWidth = hdpx(780)

function submitImpl() {
  removeModalWindow(SUCCESS_WND_UID)
  requestSelfRow()
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

let mkTextInputField = @(editableText, lenWatched, state) {
  rendObj = ROBJ_SOLID
  color = 0x00000000
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  size = [componentWidth, hdpx(200)]
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    {
      size = flex()
      rendObj = ROBJ_BOX
      borderWidth = hdpxi(1)
      padding = hdpx(10)
      borderColor = 0xFFFFFFFF
      fillColor = 0x50000000
      children = {
        size = flex()
        rendObj = ROBJ_TEXTAREA
        behavior = [Behaviors.TextAreaEdit, Behaviors.WheelScroll]
        color = 0xFFFFFFFF
        editableText
        function onChange(etext) {
          let s = utf8(etext.text)
          if (s.charCount() > MAX_MESSAGE_CHARS) {
            editableText.text = "".concat(utf8(editableText.text).slice(0, MAX_MESSAGE_CHARS))
            return
          }
          state.set(editableText.text)
        }
      }.__update(fontTinyAccented)
    }
    @() {
      watch = lenWatched
      hplace = ALIGN_LEFT
      rendObj = ROBJ_TEXT
      text = loc("contacts/report/message/max_chars", { maxChars = MAX_MESSAGE_CHARS, currentChars = lenWatched.get() })
    }
  ]
}

let mkTextInputLabel = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = defColor
}.__update(fontSmall)

function formBlock() {
  let message = EditableText(fieldMessage.get())
  let lenWatched = Computed(@() utf8(fieldMessage.get()).charCount())
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = hdpx(25)
    children = [
      mkTextInputLabel(loc("msgbox/report/selectReason"))
      dropDownMenu({
        values = categoryCfg,
        currentOption = fieldCategory,
        valToString = @(v) loc($"support/form/report/{v}"),
        setValue = @(v) fieldCategory.set(v),
        onAttach = @() fieldCategory.get() == "" ? fieldCategory.set(categoryCfg[0])
          : null
      })
      mkTextInputLabel(loc("msgbox/report/addComment"))
      mkTextInputField(message, lenWatched, fieldMessage)
    ]
  }
}

let mkButtons = {
  minWidth = SIZE_TO_CONTENT
  size = [componentWidth, SIZE_TO_CONTENT]
  gap = componentWidth - defButtonMinWidth * 2
  flow = FLOW_HORIZONTAL
  children = [
    textButtonCommon(utf8ToUpper(loc("msgbox/btn_cancel")), close, { size = [defButtonMinWidth, SIZE_TO_CONTENT] })
    mkSpinnerHideBlock(isRequestInProgress, textButtonCommon(utf8ToUpper(loc("contacts/report/short")), onSubmit), {
      size = [defButtonMinWidth, SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      vplace = ALIGN_CENTER
    })
  ]
}

let content = @()
  modalWndBg.__merge({
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    children = [
      modalWndHeader(loc("mainmenu/titlePlayerReport"))
      {
        flow = FLOW_VERTICAL
        valign = ALIGN_TOP
        padding = const [hdpx(25), hdpx(40), hdpx(40), hdpx(40)]
        gap = hdpx(25)
        minWidth = SIZE_TO_CONTENT
        size = FLEX_H
        children = [
          formBlock
          mkButtons
        ]
      }
    ]
  })

isReportStatusSuccessed.subscribe(function(v) {
  if (v && selectedPlayerForReport.get())
    openMsgBox({
      uid = SUCCESS_WND_UID
      title = loc("support/form/report/success")
      text = loc("support/form/report/successDescription")
      buttons = [{ id = "ok", styleId = "PRIMARY", cb = close }]
    })
})

isReportStatusRejected.subscribe(function(v) {
  if (v && selectedPlayerForReport.get())
    openMsgBox({
      uid = REJECT_WND_UID
      title = loc("support/form/report/reject")
      text = loc("support/form/report/rejectDescription")
      buttons = [{ id = "ok", styleId = "PRIMARY", cb = close }]
    })
})

selectedPlayerForReport.subscribe(function(v) {
  removeModalWindow(REPORT_WND_UID)
  if (v == null)
    return
  addModalWindow(bgShaded.__merge({
    key = REPORT_WND_UID
    hotkeys = [[btnBUp, loc("mainmenu/btnClose")]]
    animations = wndSwitchAnim
    onClick = @() openMsgBox({
      text = loc("msgbox/leaveWindow")
      buttons = [
        { id = "cancel", isCancel = true }
        { id = "ok", styleId = "PRIMARY", cb = close }
      ]
    })
    onDetach = @() selectedPlayerForReport.set(null)
    sound = { click = "click" }
    size = const [sw(100), sh(100)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = content
  }))
})
