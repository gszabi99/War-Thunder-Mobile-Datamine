from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { addModalWindow, removeModalWindow, hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { modalWndBg } = require("%rGui/components/modalWnd.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { slotBarSelectWnd } = require("slotBar.nut")
let { selectedUnitToSlot, slots, closeSelectUnitToSlotWnd, canOpenSelectUnitWithModal, selectedUnitAABBKey } = require("slotBarState.nut")
let { isPurchEffectVisible } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { setUnitToScroll } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")

let WND_UID = "selectUnitToSlot"

let needOpen = Computed(@() selectedUnitToSlot.get() != null
  && !isPurchEffectVisible.get()
  && !isInBattle.get()
  && slots.get().len() > 0
)
let canOpen = Computed(@() !hasModalWindows.get() || canOpenSelectUnitWithModal.get())
let shouldOpen = Computed(@() needOpen.get() && canOpen.get())

function mkBgText(rect) {
  let text = loc("slotbar/chooseSlot", { unit = loc(getUnitLocId(selectedUnitToSlot.get())) })
  let textSize = calc_str_box(text, fontSmall)
  
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
  onClick = closeSelectUnitToSlotWnd
  children = [
    mkCutBg([rect])
    {
      margin = [rect.b + hdpx(50), 0, saBorders[1], 0]
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_LEFT
      children = modalWndBg.__merge({ children = slotBarSelectWnd })
    }
    mkBgText(rect)
  ]
  animations = [
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.2, easing = OutQuad, play = true }
    { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.1, easing = OutQuad, playFadeOut = true }
  ]
})

function open() {
  setUnitToScroll(selectedUnitToSlot.get())
  resetTimeout(0.1, function() {
    if (!shouldOpen.get())
      return
    let rect = gui_scene.getCompAABBbyKey(selectedUnitAABBKey.get())
    if (rect)
      openImpl(rect)
  })
}

if (shouldOpen.get())
  open()
shouldOpen.subscribe(@(v) v ? open() : null)
needOpen.subscribe(@(v) v ? null : removeModalWindow(WND_UID))
