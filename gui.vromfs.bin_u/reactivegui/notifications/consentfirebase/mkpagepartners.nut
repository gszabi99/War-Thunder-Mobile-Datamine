from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "%rGui/notifications/consentFirebase/consentComps.nut" import mkContent, mkLinkText, gapAfterPoint
from "%rGui/notifications/consentFirebase/consentState.nut" import isOpenedPartners, getPartnersList


let close = @() isOpenedPartners.set(false)

let pointSize = [hdpx(3), hdpx(3)]

let partnerRow = @(p) {
  size = FLEX_H
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
          text = p.name
        }.__update(fontTiny)
      ]
    }
    mkLinkText(loc("consentWnd/partners/header/policy"),
      @() eventbus_send("openUrl", { baseUrl = p.policy }),
      { padding = [0, 0, 0, gapAfterPoint + pointSize[0]] })
  ]
}

let partnersComp = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = getPartnersList().map(partnerRow)
}

return @() mkContent(loc("consentWnd/main/partners"), partnersComp, null, close)
