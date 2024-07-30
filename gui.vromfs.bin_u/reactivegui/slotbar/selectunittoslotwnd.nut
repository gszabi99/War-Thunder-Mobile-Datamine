from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow, hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { msgBoxBg } = require("%rGui/components/msgBox.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { slotBarSelectWnd } = require("slotBar.nut")
let { selectedUnitToSlot, slots, resetSelectedUnitToSlot } = require("slotBarState.nut")
let { resetTimeout } = require("dagor.workcycle")
let { isPurchEffectVisible } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { unitToScroll } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { getBox } = require("%rGui/tutorial/tutorialWnd/tutorialUtils.nut")
let { treeNodeUnitPlateKey } = require("%rGui/unitsTree/mkUnitPlate.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")


let WND_UID = "selectUnitToSlot"

let needSelectUnitResearch = keepref(Computed(@() selectedUnitToSlot.get() != null && !isPurchEffectVisible.get()))

function close() {
  resetSelectedUnitToSlot()
  removeModalWindow(WND_UID)
}

function mkBgText(rect) {
  let text = loc("slotbar/chooseSlot", { unit = loc(getUnitLocId(selectedUnitToSlot.get())) })
  let textSize = calc_str_box(text, fontSmall)
  // align text relative to the selected unit
  let posX = rect.l - ((textSize[0] - (rect.r - rect.l)) / 2)
  return {
    size = flex()
    pos = [posX, rect.t - hdpx(75)]
    rendObj = ROBJ_TEXT
    text
  }.__update(fontSmall)
}

let openImpl = @(rect) addModalWindow({
  key = WND_UID
  onClick = close
  children = [
    mkCutBg([rect])
    {
      margin = [rect.b + hdpx(50), 0, 0, 0]
      children = msgBoxBg.__merge({ children = slotBarSelectWnd })
    }
    mkBgText(rect)
  ]
  animations = wndSwitchAnim
})

function openWndIfCan() {
  if (needSelectUnitResearch.get()
      && !hasModalWindows.get()
      && !isInBattle.get()
      && !isPurchEffectVisible.get()
      && slots.get().len() > 0) {
    unitToScroll.set(selectedUnitToSlot.get())
    resetTimeout(0.1, function() {
      let rect = getBox(treeNodeUnitPlateKey(selectedUnitToSlot.get()))
      if (rect)
        openImpl(rect)
    })
  }
}

if (needSelectUnitResearch.get())
  openWndIfCan()
needSelectUnitResearch.subscribe(@(v) v ? openWndIfCan() : close())

return openWndIfCan
