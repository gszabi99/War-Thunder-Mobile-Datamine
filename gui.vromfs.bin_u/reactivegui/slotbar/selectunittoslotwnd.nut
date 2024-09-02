from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { addModalWindow, removeModalWindow, hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { msgBoxBg } = require("%rGui/components/msgBox.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { slotBarSelectWnd } = require("slotBar.nut")
let { selectedUnitToSlot, slots, resetSelectedUnitToSlot } = require("slotBarState.nut")
let { isPurchEffectVisible } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { unitToScroll } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { treeNodeUnitPlateKey } = require("%rGui/unitsTree/mkUnitPlate.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")


let WND_UID = "selectUnitToSlot"

let needOpen = Computed(@() selectedUnitToSlot.get() != null
  && !isPurchEffectVisible.get()
  && !isInBattle.get()
  && slots.get().len() > 0
)
let canOpen = Computed(@() !hasModalWindows.get())
let shouldOpen = Computed(@() needOpen.get() && canOpen.get())

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

function open() {
  unitToScroll.set(selectedUnitToSlot.get())
  resetTimeout(0.1, function() {
    if (!shouldOpen.get())
      return
    let rect = gui_scene.getCompAABBbyKey(treeNodeUnitPlateKey(selectedUnitToSlot.get()))
    if (rect)
      openImpl(rect)
  })
}

if (shouldOpen.get())
  open()
shouldOpen.subscribe(@(v) v ? open() : null)
needOpen.subscribe(@(v) v ? null : close())
