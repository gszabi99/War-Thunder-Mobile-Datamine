from "%globalsDarg/darg_library.nut" import *
let { addModalWindowWithHeader, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")

let boosterDescUid = "booster_desc_wnd_uid"
let close = @() removeModalWindow(boosterDescUid)

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
      size = FLEX_H
      minWidth = hdpx(500)
      rendObj = ROBJ_TEXTAREA
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      behavior = Behaviors.TextArea
      padding = const [0, hdpx(30)]
      text = loc($"booster/desc/{bst}")
    }.__update(fontSmall)
  ]
}

let content = @(bst) {
  size = [hdpx(1000), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  behavior = Behaviors.Button
  onClick = close
  children = [
    rewardInfo(bst)
    {
      padding = const [hdpx(20), 0, hdpx(40), 0]
      hplace = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      color = 0xFFE0E0E0
      text = loc("TapAnyToContinue")
    }.__update(fontSmallAccentedShaded)
  ]
}

let boosterDescWnd = @(bst) addModalWindowWithHeader(boosterDescUid, loc($"boosters/{bst}"), content(bst))

return boosterDescWnd