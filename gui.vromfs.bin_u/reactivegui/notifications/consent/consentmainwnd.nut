from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { register_command } = require("console")
let { bgShaded, bgMessage } = require("%rGui/style/backgrounds.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { urlUnderline, linkColor } = require("consentComps.nut")
let { msgBoxHeaderWithClose } = require("%rGui/components/msgBox.nut")
let { isOpenedConsentWnd, isOpenedPartners, isOpenedManage points} = require("consentState.nut")

let key = "consentMain"
let close = @() isOpenedConsentWnd(false)

function onClickConsent() {
  points(points.get().map(@(_) true))
  eventbus_send("consent.onCustomFormSave", points.get())
  close()
}

function onClickDontConsent() {
  points(points.get().map(@(_) false))
  eventbus_send("consent.onCustomFormSave", points.get())
  close()
}

let mainButtons = {
  size = [flex(), SIZE_TO_CONTENT]
  padding = [hdpx(20), hdpx(50), hdpx(40), hdpx(50)]
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  children = [
    textButtonCommon(loc("consentWnd/btns/notConsent"), onClickDontConsent)
    {size = flex()}
    textButtonPrimary(loc("consentWnd/btns/consent"), onClickConsent)
  ]
}

let textCtor = @(id){
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc(id)
}.__update(fontTiny)

let linkTextCtor = @(id, onClick, ovr = {}){
  padding = [hdpx(30), 0]
  rendObj = ROBJ_TEXT
  text = loc(id)
  onClick
  behavior = Behaviors.Button
  color = linkColor
  children = urlUnderline
}.__update(fontTiny, ovr)

let desc = {
  size = flex()
  padding = [hdpx(20), hdpx(70)]
  flow = FLOW_VERTICAL
  children = [
    textCtor("consentWnd/main/consentMesssagePart1")
    linkTextCtor("consentWnd/main/partners", @() isOpenedPartners(true))
    textCtor("consentWnd/main/consentMesssagePart2")
    linkTextCtor("consentWnd/main/manage", @() isOpenedManage(true), { hplace = ALIGN_CENTER })
  ]
}


let content = bgMessage.__merge({
  size = [pw(50), ph(80)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    msgBoxHeaderWithClose(loc("consentWnd/main/header"), function(){
      eventbus_send("consent.onCustomFormSave", null)
      close()
    })
    desc
    mainButtons
  ]
})

let consentWnd = bgShaded.__merge({
  key
  size = flex()
  children = content
  animations = wndSwitchAnim
  onClick = @() null
})


if (isOpenedConsentWnd.get())
  addModalWindow(consentWnd)
isOpenedConsentWnd.subscribe(@(v) v ? addModalWindow(consentWnd) : removeModalWindow(key))

register_command(@() isOpenedConsentWnd(true), "ui.consentWnd")