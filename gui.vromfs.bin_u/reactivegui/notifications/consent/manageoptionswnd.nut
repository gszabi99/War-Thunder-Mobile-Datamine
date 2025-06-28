from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { urlUnderline, gapAfterPoint, linkColor } = require("consentComps.nut")
let { openMsgBox, msgBoxText, wndWidthDefault } = require("%rGui/components/msgBox.nut")
let { isOpenedManage, defaultPointsTable, savedPoints,
  applyConsent} = require("consentState.nut")

let key = "consentManage"
let close = @() isOpenedManage(false)

let checkSize = [hdpxi(30), hdpxi(30)]

function copyPoints(v){
  let savedPointsClone = clone v
  if((savedPointsClone?.len() ?? 0) == 0)
    return defaultPointsTable
  return savedPointsClone
}

let choosenPoints = Watched(copyPoints(savedPoints.get()))
savedPoints.subscribe(@(v) choosenPoints.set(copyPoints(v)))

function checkBox(p){
  let isChecked = Computed(@() choosenPoints.get()[p])
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
  padding = const [hdpx(20),hdpx(70)]
  flow = FLOW_VERTICAL
  gap = gapAfterPoint
  children = [
    @() {
      watch = choosenPoints
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      valign = ALIGN_TOP
      gap = gapAfterPoint
      behavior = Behaviors.Button
      function onClick() {
        let oldValue = choosenPoints.get()[p]
        choosenPoints(choosenPoints.get().__merge({[p] = !oldValue}))
      }
      children = [
        checkBox(p)
        {
          size = FLEX_H
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc($"consentWnd/manage/{p}")
        }.__update(fontTiny)
      ]
    }
    mkAdditionalInfo(p)
  ]
}

let manageButtons = @(){
  watch = choosenPoints
  size = FLEX_H
  padding = const [hdpx(20), hdpx(50), hdpx(40), hdpx(50)]
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  children = [
    textButtonCommon(loc("consentWnd/manage/acceptAll"), @() applyConsent(defaultPointsTable.map(@(_) true), {wnd="consentManage", action="accept_all"}))
    {size = flex()}
    textButtonPrimary(loc("consentWnd/manage/acceptChoosen"), @() applyConsent(choosenPoints.get(), {wnd="consentManage", action="accept_chosen"}))
  ]
}

let pointsComp = @() {
  watch = choosenPoints
  size = flex()
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = choosenPoints.get()?.keys().map(optionRow) ?? []
}

let content = modalWndBg.__merge({
  size = [wndWidthDefault, hdpx(880)]
  flow = FLOW_VERTICAL
  children = [
    modalWndHeaderWithClose(loc("consentWnd/main/manage"), close)
    pointsComp
    manageButtons
  ]
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
