from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradDoubleTexOffset, mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { closeWndBtn, closeWndBtnSize } = require("%rGui/components/closeWndBtn.nut")


let wndHeaderHeight = evenPx(76)
let closeMargin = (wndHeaderHeight - closeWndBtnSize) / 2

let modalWndBg = freeze({
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  stopMouse = true
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(0xFF304453, 0xFF030C13)
})

let modalWndHeaderBg = freeze({
  size = [ flex(), wndHeaderHeight ]
  padding = const [0, hdpx(20)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER

  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(300)]
  color = 0xFF4D88A4
})

let modalWndHeader = @(text, ovr = {}) modalWndHeaderBg.__merge({
  children = {
    rendObj = ROBJ_TEXT
    text
  }.__update(fontSmall)
}, ovr)

let modalWndHeaderWithClose = @(text, close, ovr = {}) modalWndHeaderBg.__merge({
  children = [
    {
      rendObj = ROBJ_TEXT
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      padding = [0, wndHeaderHeight]
      text
    }.__update(fontSmall)
    closeWndBtn(close, { margin = closeMargin })
  ]
}, ovr)

return {
  wndHeaderHeight

  modalWndBg
  modalWndHeaderBg
  modalWndHeader
  modalWndHeaderWithClose
}