from "%globalsDarg/darg_library.nut" import *
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/components/msgBox.nut" import wndWidthDefault
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader, wndHeaderHeight
from "%rGui/components/closeWndBtn.nut" import closeWndBtn
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkLink, mkBackBtn

const wndW = wndWidthDefault
const wndH = hdpx(880)
let gapAfterPoint = hdpx(10)

let mkLinkText = @(text, onClick, ovr = {}) mkLink(text, onClick, fontTiny.__merge(ovr))

const descPadding = hdpx(50)
const footerBtnsPadding = hdpx(50)
const wndFooterH = defButtonHeight + (2 * footerBtnsPadding)
const wndDescH = wndH - wndHeaderHeight - wndFooterH

function mkContent(titleStr, descChildren, footerBtnsChildren, onClose, isRootWnd = false) {
  let scrollHandler = ScrollHandler()
  return modalWndBg.__merge({
    key = titleStr
    size = [wndW, wndH]
    flow = FLOW_VERTICAL
    children = [
      {
        size = [wndW, wndHeaderHeight]
        valign = ALIGN_CENTER
        children = [
          modalWndHeader(titleStr)
          onClose == null ? null : (isRootWnd ? closeWndBtn : mkBackBtn)(onClose, { hotkeys = [btnBEscUp] })
        ]
      }
      {
        size = [wndW, wndDescH + (footerBtnsChildren == null ? wndFooterH : 0)]
        children = makeVertScroll(
          {
            size = FLEX_H
            padding = footerBtnsChildren !=  null
              ? [descPadding, descPadding, 0, descPadding]
              : descPadding
            flow = FLOW_VERTICAL
            children = descChildren
          },
          {
            rootBase = {
              behavior = [Behaviors.Pannable, Behaviors.ScrollEvent]
              touchMarginPriority = TOUCH_BACKGROUND
            }
            scrollHandler
          }
        )
      }
      footerBtnsChildren == null
        ? null
        : {
            size = [wndW, wndFooterH]
            padding = footerBtnsPadding
            vplace = ALIGN_BOTTOM
            halign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            children = footerBtnsChildren
          }
    ]
  })
}

return {
  mkContent
  mkLinkText
  gapAfterPoint
}