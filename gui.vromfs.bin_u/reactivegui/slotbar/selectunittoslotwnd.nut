from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { addModalWindow, removeModalWindow, hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { modalWndBg } = require("%rGui/components/modalWnd.nut")
let { slotBarSelectWnd } = require("%rGui/slotBar/slotBar.nut")
let { selectedUnitToSlot, closeSelectUnitToSlotWnd, canOpenSelectUnitWithModal, selectedUnitAABBKey } = require("%rGui/slotBar/slotBarState.nut")
let { isPurchEffectVisible } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { setUnitToScroll } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let { mkTreeNodesUnitPlate } = require("%rGui/unitsTree/mkUnitPlate.nut")

let WND_UID = "selectUnitToSlot"

let needOpen = Computed(@() selectedUnitToSlot.get() != null
  && !isPurchEffectVisible.get()
  && !isInBattle.get()
  && curSlots.get().len() > 0
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

function openImpl() {
  let rect = Watched(null)
  let xmbNode = XmbNode()
  let unit = Computed(@() campMyUnits.get()?[selectedUnitToSlot.get()] ?? campUnitsCfg.get()?[selectedUnitToSlot.get()])
  function updateRect() {
    let new = gui_scene.getCompAABBbyKey(selectedUnitAABBKey.get())
    if (new != null && !isEqual(new, rect.get()))
      rect.set(new)
  }
  updateRect()
  if (rect.get() == null)
    return false

  addModalWindow({
    key = WND_UID
    onClick = closeSelectUnitToSlotWnd
    children = [
      @() {
        watch = [rect, unit]
        key = rect
        size = flex()
        onAttach = @() setInterval(0.05, updateRect)
        onDetach = @() clearTimer(updateRect)
        children = !rect.get() || !unit.get() ? null
          : [
              mkCutBg([rect.get()])
              mkTreeNodesUnitPlate(unit.get(), xmbNode,
                { pos = [rect.get().l, rect.get().t], dragStartDelay = null, transform = {} })
              mkBgText(rect.get())
            ]
      }
      {
        margin = [0, 0, saBorders[1], 0]
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_LEFT
        children = modalWndBg.__merge({ children = slotBarSelectWnd })
      }
    ]
    animations = [
      { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.2, easing = OutQuad, play = true }
      { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.1, easing = OutQuad, playFadeOut = true }
    ]
  })
  return true
}

function open() {
  setUnitToScroll(selectedUnitToSlot.get())
  resetTimeout(0.1, function() {
    if (!shouldOpen.get())
      return
    if (!openImpl())
      closeSelectUnitToSlotWnd()
  })
}

if (shouldOpen.get())
  open()
shouldOpen.subscribe(@(v) v ? open() : null)
needOpen.subscribe(@(v) v ? null : removeModalWindow(WND_UID))
