from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/itemsState.nut" import itemsOrder
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%rGui/components/currencyComp.nut" import mkCurrencyImage
from "%rGui/components/currencyStyles.nut" import CS_GAMERCARD
from "%rGui/style/gradients.nut" import gradCircularSmallHorCorners, gradCircCornerOffset
from "%rGui/style/stdColors.nut" import hoverColor
from "%rGui/unit/hangarUnit.nut" import hangarUnit
from "%rGui/unit/unitItemAccess.nut" import isItemAllowedForUnit
from "itemsBuyState.nut" import isOpenedItemWnd


const bgIconSize = hdpx(70)
let stateFlags = Watched(0)

let plus = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  pos = const [pw(30), ph(35)]
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  text = "+"
}.__update(fontBigShaded)

let hoverBg = {
  size = const [pw(150), FLEX]
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  color = hoverColor
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}

let battleItemsBtn = @() {
  watch = [itemsOrder, hangarUnit, stateFlags]
  size = FLEX_V
  behavior = Behaviors.Button
  onElemState = @(sf) stateFlags.set(sf)
  function onClick() {
    isOpenedItemWnd.set(true)
    sendUiBqEvent("open_items_window", { id = "open", from = "hangar" })
  }
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = [
    stateFlags.get() & S_HOVER ? hoverBg : null
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(-30)
      sound = { click  = "click" }
      children = itemsOrder.get()
        .filter(@(v) hangarUnit.get()?.name == null || isItemAllowedForUnit(v, hangarUnit.get().name))
        .map(@(id) {
          size = bgIconSize
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#consumables_bg.avif:{bgIconSize}:{bgIconSize}:P")
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = mkCurrencyImage(id, CS_GAMERCARD.iconSize)
        })
        .append(plus)
      transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    }
  ]
}

return battleItemsBtn