from "%globalsDarg/darg_library.nut" import *
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")

let boosterDescUid = "booster_desc_wnd_uid"

let close = @() removeModalWindow(boosterDescUid)

let descriptionWndBg = 0x90000000
let descriptionWndWidth = hdpx(1000)

let backBtn = {
  size = [flex(), gamercardHeight]
  children = backButton(close)
}

let decorativeLine = {
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = 0xFFFFFFFF
  size = [ descriptionWndWidth, hdpx(6) ]
}

let rewardInfo = @(bst) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0 , gradDoubleTexOffset]
  screenOffs = [0, hdpx(250)]
  color = 0xFF000000
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  padding = [hdpx(50), 0]
  gap = hdpx(30)
  children = [
    mkCurrencyImage(bst, hdpxi(100))
    {
      size = [pw(50), hdpx(150)]
      rendObj = ROBJ_TEXTAREA
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      behavior = Behaviors.TextArea
      padding = [0, hdpx(30)]
      text = loc($"booster/desc/{bst}")
    }.__update(fontSmall)
  ]
}

let content = @(bst) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    decorativeLine
    rewardInfo(bst)
    decorativeLine
  ]
}

let boosterDescWnd = @(bst) addModalWindow({
  key = boosterDescUid
  hotkeys = [[btnBEscUp, { action = close }]]
  onClick = close
  rendObj = ROBJ_SOLID
  size = flex()
  color = descriptionWndBg
  padding = saBordersRv
  behavior = Behaviors.Button
  children = [
    backBtn
    content(bst)
  ]
  animations = wndSwitchAnim

})

return boosterDescWnd