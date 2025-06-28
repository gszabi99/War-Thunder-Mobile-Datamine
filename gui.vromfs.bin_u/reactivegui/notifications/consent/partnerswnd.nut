from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { eventbus_send } = require("eventbus")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { gapAfterPoint, urlUnderline, linkColor } = require("consentComps.nut")
let { isOpenedPartners } = require("consentState.nut")

let key = "consentPartners"
let close = @() isOpenedPartners(false)

let partners = ["google", "meta", "unity"]

let pointSize = [hdpx(3), hdpx(3)]

let partnerRow = @(p){
  size = FLEX_H
  padding = const [hdpx(20),hdpx(70)]
  flow = FLOW_VERTICAL
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = gapAfterPoint
      children = [
        {
          size = pointSize
          rendObj = ROBJ_VECTOR_CANVAS
          lineWidth = hdpx(2)
          commands = [
            [VECTOR_ELLIPSE, 50, 50, 50, 50],
          ]
        }
        {
          rendObj = ROBJ_TEXT
          text = loc($"consentWnd/partners/header/{p}")
        }.__update(fontTiny)
      ]
    }
    {
      padding = [0, 0, 0, gapAfterPoint + pointSize[0]]
      rendObj = ROBJ_TEXT
      text = loc("consentWnd/partners/header/policy")
      behavior = Behaviors.Button
      onClick = @() eventbus_send("openUrl", { baseUrl = loc($"url/policy/{p}") })
      color = linkColor
      children = urlUnderline
    }.__update(fontTiny)
  ]
}

let closeBtn = {
  padding = const [hdpx(20), 0]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  children = textButtonPrimary(loc("msgbox/btn_ok"), close)
}

let content = modalWndBg.__merge({
  size = hdpx(700)
  flow = FLOW_VERTICAL
  children = [
    modalWndHeaderWithClose(loc("consentWnd/main/partners"), close)
  ].extend(partners.map(partnerRow))
  .append(closeBtn)
})

let partnersWnd = bgShaded.__merge({
  key
  size = flex()
  onClick = @() null
  children = content
  animations = wndSwitchAnim
})

if (isOpenedPartners.get())
  addModalWindow(partnersWnd)
isOpenedPartners.subscribe(@(v) v ? addModalWindow(partnersWnd) : removeModalWindow(key))
