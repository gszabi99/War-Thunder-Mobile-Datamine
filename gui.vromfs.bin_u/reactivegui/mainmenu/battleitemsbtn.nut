from "%globalsDarg/darg_library.nut" import *
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { isItemAllowedForUnit } = require("%rGui/unit/unitItemAccess.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { CS_GAMERCARD } = require("%rGui/components/currencyStyles.nut")
let { isOpenedItemWnd } = require("itemsBuyState.nut")
let { itemsOrder } = require("%appGlobals/itemsState.nut")

let bgIconSize = hdpx(70)
let stateFlags = Watched(0)

let plus = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  pos = [pw(30), ph(35)]
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  text = "+"
}.__update(fontBigShaded)

let hoverBg = {
  size = [pw(150), flex()]
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