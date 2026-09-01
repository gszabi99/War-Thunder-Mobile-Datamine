from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/currencyComp.nut" import mkCurrencyImage
from "%rGui/components/modalWindows.nut" import addModalWindowWithHeader, removeModalWindow


const boosterDescUid = "booster_desc_wnd_uid"
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
  size = const [hdpx(1000), SIZE_TO_CONTENT]
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