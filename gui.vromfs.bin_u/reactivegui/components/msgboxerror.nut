from "%globalsDarg/darg_library.nut" import *
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { defaultBtnsCfg, msgBoxText, mkCustomMsgBoxWnd, mkMsgBoxBtnsSet
} = require("%rGui/components/msgBox.nut")
let { addModalWindow, removeModalWindow } = require("modalWindows.nut")
let { urlText } = require("%rGui/components/urlText.nut")

let wndWidth = hdpx(1500)
let wndHeight = hdpx(700)

let msgContent = @(text, moreInfoLink) {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    msgBoxText(text, { size = [flex(), SIZE_TO_CONTENT] })
    urlText(moreInfoLink, moreInfoLink, { ovr = fontTiny })
  ]
}

let function openMsgBoxError(text, uid = null, title = null, buttons = defaultBtnsCfg,
  moreInfoLink = "", debugString = ""
) {
  uid = uid ?? $"msgbox_{text}"
  removeModalWindow(uid)
  addModalWindow(bgShaded.__merge({
    key = uid
    size = flex()
    onClick = @() null
    children = {
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      children = [
        mkCustomMsgBoxWnd(title, msgContent(text, moreInfoLink), mkMsgBoxBtnsSet(uid, buttons),
          { size = [wndWidth, wndHeight] })
        {
          hplace = ALIGN_RIGHT
          rendObj = ROBJ_TEXT
          text = debugString
          color = 0xFFC0C0C0
        }.__update(fontTiny)
      ]
    }
  }))
  return uid
}

return kwarg(openMsgBoxError)
