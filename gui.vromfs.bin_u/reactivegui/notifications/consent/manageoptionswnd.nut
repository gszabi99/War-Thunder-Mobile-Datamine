from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgShaded, bgMessage } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { urlUnderline, gapAfterPoint, linkColor } = require("consentComps.nut")
let { msgBoxHeaderWithClose, openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { isOpenedManage, isOpenedConsentWnd, points} = require("consentState.nut")

let key = "consentManage"
let close = @() isOpenedManage(false)

let checkSize = [hdpxi(30), hdpxi(30)]

function checkBox(p){
  let isChecked = Computed(@() points.get()[p])
  return @(){
    watch = isChecked
    size = checkSize
    rendObj = ROBJ_BOX
    opacity = isChecked.get() ? 1.0 : 0.5
    borderWidth = hdpx(3)
    children = isChecked.get() ? {
      size = checkSize
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image =  Picture($"ui/gameuiskin#check.svg:{checkSize[0]}:{checkSize[1]}:P")
      keepAspect = KEEP_ASPECT_FIT
    } : null
  }

}

let additionalInfoWnd = @(text) openMsgBox({
  text = msgBoxText(text, fontTinyAccented),
  title = loc("msgbox/error_link_format_game"),
})

let mkAdditionalInfo = @(p){
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Button
  onClick = @() additionalInfoWnd(loc($"consentWnd/manage/desc/{p}"))
  text = loc("msgbox/error_link_format_game")
  color = linkColor
  children = urlUnderline
}.__update(fontTiny)


let optionRow = @(p){
  key
  size = flex()
  padding = [hdpx(20),hdpx(70)]
  flow = FLOW_VERTICAL
  gap = gapAfterPoint
  children = [
    @() {
      watch = points
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_TOP
      gap = gapAfterPoint
      behavior = Behaviors.Button
      function onClick() {
        let oldValue = points.get()[p]
        points(points.get().__merge({[p] = !oldValue}))
      }
      children = [
        checkBox(p)
        {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc($"consentWnd/manage/{p}")
        }.__update(fontTiny)
      ]
    }
    mkAdditionalInfo(p)
  ]
}
function onClickAcceptAll() {
  points(points.get().map(@(_) true))
  eventbus_send("consent.onCustomFormSave", points.get())
  close()
  isOpenedConsentWnd(false)
}

function onClickConfirmCustom() {
  eventbus_send("consent.onCustomFormSave", points.get())
  close()
  isOpenedConsentWnd(false)
}

let manageButtons = {
  size = [flex(), SIZE_TO_CONTENT]
  padding = [hdpx(20), hdpx(50), hdpx(40), hdpx(50)]
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  children = [
    textButtonCommon(loc("consentWnd/manage/accept"), onClickAcceptAll)
    {size = flex()}
    textButtonPrimary(loc("consentWnd/manage/confirm"), onClickConfirmCustom)
  ]
}

let content = bgMessage.__merge({
  size = [pw(50), ph(80)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    msgBoxHeaderWithClose(loc("consentWnd/main/manage"), close)
  ].extend(points.get().keys().map(optionRow))
  .append(manageButtons)
})

let manageWnd = bgShaded.__merge({
  key
  size = flex()
  children = content
  onClick = @() null
  animations = wndSwitchAnim
})

if (isOpenedManage.get())
  addModalWindow(manageWnd)
isOpenedManage.subscribe(@(v) v ? addModalWindow(manageWnd) : removeModalWindow(key))
