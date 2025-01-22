from "%globalsDarg/darg_library.nut" import *
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")

let boosterDescUid = "booster_desc_wnd_uid"

let close = @() removeModalWindow(boosterDescUid)

let descriptionWndWidth = hdpx(1000)

let backBtn = {
  size = [flex(), gamercardHeight]
  children = backButton(close)
}

let header = @(bst) modalWndHeader(loc($"boosters/{bst}"))

let rewardInfo = @(bst) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  padding = hdpx(50)
  gap = hdpx(30)
  children = [
    mkCurrencyImage(bst, hdpxi(100))
    {
      size = [flex(), SIZE_TO_CONTENT]
      minWidth = hdpx(500)
      rendObj = ROBJ_TEXTAREA
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      behavior = Behaviors.TextArea
      padding = [0, hdpx(30)]
      text = loc($"booster/desc/{bst}")
    }.__update(fontSmall)
  ]
}

let content = @(bst) modalWndBg.__merge({
  size = [descriptionWndWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    header(bst)
    rewardInfo(bst)
    {
      padding = [hdpx(20),0,hdpx(50),0]
      hplace = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      color = 0xFFE0E0E0
      text = loc("TapAnyToContinue")
    }.__update(fontSmallAccentedShaded)
  ]
})

let boosterDescWnd = @(bst) addModalWindow(bgShaded.__merge({
  key = boosterDescUid
  hotkeys = [[btnBEscUp, { action = close }]]
  onClick = close
  rendObj = ROBJ_SOLID
  size = flex()
  padding = saBordersRv
  behavior = Behaviors.Button
  children = [
    backBtn
    content(bst)
  ]
  animations = wndSwitchAnim

}))

return boosterDescWnd