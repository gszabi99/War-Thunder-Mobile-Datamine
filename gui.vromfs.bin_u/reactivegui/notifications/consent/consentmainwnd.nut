from "%globalsDarg/darg_library.nut" import *
let logC = log_with_prefix("[consent] ")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { urlUnderline, linkColor } = require("%rGui/notifications/consent/consentComps.nut")
let { wndWidthDefault } = require("%rGui/components/msgBox.nut")
let { isOpenedConsentWnd,needOpenConsentWnd, isOpenedPartners, isOpenedManage,
  defaultPointsTable, applyConsent, savedPoints, isConsentAcceptedOnce, setupAnalytics} = require("%rGui/notifications/consent/consentState.nut")
let { can_skip_consent } = require("%appGlobals/permissions.nut")
let { closeWndBtn } = require("%rGui/components/closeWndBtn.nut")

let key = "consentMain"
let close = @() needOpenConsentWnd.set(false)

let mainButtons = {
  size = FLEX_H
  padding = const [hdpx(20), hdpx(50), hdpx(40), hdpx(50)]
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  children = [
    textButtonCommon(utf8ToUpper(loc("consentWnd/btns/notConsent")), @() applyConsent(defaultPointsTable.map(@(_) false), {wnd="consentMain", action="dont_consent"}))
    {size = flex()}
    textButtonPrimary(utf8ToUpper(loc("consentWnd/btns/consent")), @() applyConsent(defaultPointsTable, {wnd="consentMain", action="accept_all"}))
  ]
}

let textCtor = @(id){
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc(id)
}.__update(fontTiny)

let linkTextCtor = @(id, onClick, ovr = {}){
  padding = const [hdpx(30), 0]
  rendObj = ROBJ_TEXT
  text = loc(id)
  onClick
  behavior = Behaviors.Button
  color = linkColor
  children = urlUnderline
}.__update(fontTiny, ovr)

let desc = {
  size = flex()
  padding = const [hdpx(20), hdpx(70)]
  flow = FLOW_VERTICAL
  children = [
    textCtor("consentWnd/main/consentMesssagePart1")
    linkTextCtor("consentWnd/main/partners", @() isOpenedPartners.set(true))
    textCtor("consentWnd/main/consentMesssagePart2")
    linkTextCtor("consentWnd/main/manage", @() isOpenedManage.set(true), { hplace = ALIGN_CENTER })
  ]
}


let content = modalWndBg.__merge({
  size = [wndWidthDefault, hdpx(880)]
  flow = FLOW_VERTICAL
  children = [
    @(){
      watch = can_skip_consent
      size = FLEX_H
      valign = ALIGN_CENTER
      children = [
        modalWndHeader(loc("consentWnd/main/header"))
        can_skip_consent.get()
          ? closeWndBtn(function(){
            if (!isConsentAcceptedOnce.get()) {
              savedPoints.set(defaultPointsTable.map(@(_) false))
              logC("consent skipped")
              sendUiBqEvent("ads_consent_firebase", { id = "consent_skip" })
              setupAnalytics()
            }
            close()
          })
          : null
      ]
    }
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