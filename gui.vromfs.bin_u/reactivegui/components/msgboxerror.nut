from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/msgBox.nut" import defaultBtnsCfg, msgBoxText, mkCustomMsgBoxWnd, mkMsgBoxBtnsSet
from "%rGui/components/urlText.nut" import urlText
from "%rGui/style/backgrounds.nut" import bgShaded


const wndWidth = hdpx(1500)
const wndHeight = hdpx(700)

let msgContent = @(text, moreInfoLink) {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    msgBoxText(text, { size = FLEX_H })
    urlText(moreInfoLink, moreInfoLink, { ovr = fontTiny })
  ]
}

function openMsgBoxError(text, uid = null, title = null, buttons = defaultBtnsCfg,
  moreInfoLink = "", debugString = ""
) {
  uid = uid ?? $"msgbox_{text}"
  removeModalWindow(uid)
  addModalWindow(bgShaded.__merge({
    key = uid
    size = FLEX
    onClick = @() null
    children = {
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      children = [
        mkCustomMsgBoxWnd(title, msgContent(text, moreInfoLink), mkMsgBoxBtnsSet(uid, buttons),
          { size = const [wndWidth, wndHeight] })
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
