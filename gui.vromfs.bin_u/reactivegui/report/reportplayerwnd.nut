from "%globalsDarg/darg_library.nut" import *
let utf8 = require("utf8")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgMessage, bgHeader, bgShaded, bgShadedDark } = require("%rGui/style/backgrounds.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { dropDownMenu } = require("%rGui/components/dropDownMenu.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { SUCCESS_WND_UID, REPORT_WND_UID, categoryCfg, fieldCategory, fieldMessage,
  cancel, successedClose, getFormValidationError, selectedPlayerForReport, requestSelfRow,
  isReportStatusSuccessed, MAX_MESSAGE_CHARS, isRequestInProgress } = require("reportPlayerState.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { btnBUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let aTitleScaleDelayTime = 0.05
let aTitleScaleUpTime = 0.15
let aTitleScaleDownTime = 0.15
let defColor = 0xFFFFFFFF
let componentWidth = hdpx(780)

let bgGradient = bgMessage.__merge({size = flex()})
let bgGradientComp = bgGradient.__merge({
  animations = [ { prop = AnimProp.scale, from = [1, 0], to = [1, 1],
    duration = 0.2,
    play = true, trigger = {} } ]
})

let mkTapToContinueText = @(startDelay) {
  rendObj = ROBJ_TEXT
  color = 0xFFE0E0E0
  text = loc("TapAnyToContinue")
  padding = hdpx(30)
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick = successedClose
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0,
      duration = startDelay + aTitleScaleDelayTime + aTitleScaleUpTime,
      play = true, trigger = {} }
    { prop = AnimProp.opacity, from = 0, to = 1,
      delay = startDelay + aTitleScaleDelayTime + aTitleScaleUpTime, duration = aTitleScaleDownTime,
      play = true, trigger = {} }
  ]
}.__update(fontMedium)

let messageWnd = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    bgGradientComp
    {
      flow = FLOW_VERTICAL
      valign = ALIGN_TOP
      stopMouse = true
      children = [
        bgHeader.__merge({
          size = [flex(), SIZE_TO_CONTENT]
          padding = hdpx(15)
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = {
            rendObj = ROBJ_TEXT
            text = loc("support/form/report/success")
          }.__update(fontMedium)
        })
        {
          size = SIZE_TO_CONTENT
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          padding = hdpx(100)
          children = {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            maxWidth = hdpx(800)
            halign = ALIGN_CENTER
            text = loc("support/form/report/successDescription")
          }.__update(fontMedium)
        }
        mkTapToContinueText(0.5)
      ]
    }
  ]
}

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
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = hdpx(25)
    children = [
      mkTextInputLabel(loc("msgbox/report/selectReason"))
      dropDownMenu({
        values = categoryCfg,
        currentOption = fieldCategory,
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
    textButtonCommon(loc("msgbox/btn_cancel"), cancel, { size = [defButtonMinWidth, SIZE_TO_CONTENT] })
    mkSpinnerHideBlock(isRequestInProgress, textButtonCommon(loc("contacts/report/short"), onSubmit), {
      size = [defButtonMinWidth, SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      vplace = ALIGN_CENTER
    })
  ]
}

let mkContent = @()
  bgMessage.__merge({
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    stopMouse = true
    children = [
      bgHeader.__merge({
        size = [flex(), SIZE_TO_CONTENT]
        padding = hdpx(15)
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = {rendObj = ROBJ_TEXT text = loc("mainmenu/titlePlayerReport")}.__update(fontSmallAccented)
      })
      {
        flow = FLOW_VERTICAL
        valign = ALIGN_TOP
        padding = [hdpx(25), hdpx(40), hdpx(40), hdpx(40)]
        gap = hdpx(25)
        minWidth = SIZE_TO_CONTENT
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          formBlock
          mkButtons
        ]
      }
    ]
  })

isReportStatusSuccessed.subscribe(function(v) {
  if (v && selectedPlayerForReport.get())
    addModalWindow(bgShadedDark.__merge({
      key = SUCCESS_WND_UID
      size = flex()
      onClick = successedClose
      children = messageWnd
      animations = wndSwitchAnim
    }))
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
        { id = "ok", styleId = "PRIMARY", cb = cancel }
      ]
    })
    sound = { click = "click" }
    size = [sw(100), sh(100)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = [hdpx(1000), SIZE_TO_CONTENT]
      transform = {}
      safeAreaMargin = saBordersRv
      behavior = Behaviors.BoundToArea
      children = mkContent
    }
  }))
})
