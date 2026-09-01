from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/buttonStyles.nut" import defButtonMinWidth
from "%rGui/components/dropDownMenu.nut" import dropDownMenu
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/components/textInput.nut" import multilineTextInput
from "%rGui/controlsMenu/gpActBtn.nut" import btnBUp
from "%rGui/report/reportPlayerState.nut" import REJECT_WND_UID, SUCCESS_WND_UID, REPORT_WND_UID, categoryCfg,
  fieldCategory, fieldMessage, getFormValidationError, selectedPlayerForReport, requestSelfRow, close,
  isReportStatusSuccessed, isReportStatusRejected, isRequestInProgress
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const defColor = 0xFFFFFFFF
const componentWidth = hdpx(780)

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

let mkTextInputLabel = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = defColor
}.__update(fontSmall)

function formBlock() {
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
      multilineTextInput({ state = fieldMessage })
    ]
  }
}

let mkButtons = {
  minWidth = SIZE_TO_CONTENT
  size = const [componentWidth, SIZE_TO_CONTENT]
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
