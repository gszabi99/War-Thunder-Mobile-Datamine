from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, setInterval, clearTimer
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/pServer/profile.nut" import campMyUnits, campUnitsCfg
from "%appGlobals/pServer/slots.nut" import curSlots
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow, hasModalWindows
from "%rGui/components/modalWnd.nut" import modalWndBg
from "%rGui/slotBar/slotBar.nut" import slotBarSelectWnd
from "%rGui/slotBar/slotBarState.nut" import selectedUnitToSlot, closeSelectUnitToSlotWnd, canOpenSelectUnitWithModal,
  selectedUnitAABBKey
from "%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut" import mkCutBg
from "%rGui/unit/components/unitPlateComp.nut" import unitPlateWidth, unitPlateHeight, unitPlateTiny
from "%rGui/unit/unitPurchaseEffectScene.nut" import isPurchEffectVisible
from "%rGui/unitsTree/mkUnitPlate.nut" import mkTreeNodesUnitPlate
from "%rGui/unitsTree/unitsTreeNodesState.nut" import setUnitToScroll


const WND_UID = "selectUnitToSlot"

let needOpen = Computed(@() selectedUnitToSlot.get() != null
  && !isPurchEffectVisible.get()
  && !isInBattle.get()
  && curSlots.get().len() > 0
)
let canOpen = Computed(@() !hasModalWindows.get() || canOpenSelectUnitWithModal.get())
let shouldOpen = Computed(@() needOpen.get() && canOpen.get())

function mkBgText(rect) {
  let text = loc("slotbar/chooseSlot", { unit = getUnitName(selectedUnitToSlot.get()) })
  let textSize = calc_str_box(text, fontSmall)
  
  let posX = rect.l - ((textSize[0] - (rect.r - rect.l)) / 2)
  return {
    size = FLEX
    pos = [posX, rect.t - hdpx(75)]
    rendObj = ROBJ_TEXT
    text
  }.__update(fontSmall)
}

function openImpl() {
  let rect = Watched(null)
  let xmbNode = XmbNode()
  let unit = Computed(@() campMyUnits.get()?[selectedUnitToSlot.get()] ?? campUnitsCfg.get()?[selectedUnitToSlot.get()])
  let plateSize = Computed(@() canOpenSelectUnitWithModal.get() ? [unitPlateWidth, unitPlateHeight] : unitPlateTiny)
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
        watch = [rect, unit, plateSize]
        key = rect
        size = FLEX
        onAttach = @() setInterval(0.05, updateRect)
        onDetach = @() clearTimer(updateRect)
        children = !rect.get() || !unit.get() ? null
          : [
              mkCutBg([rect.get()])
              mkTreeNodesUnitPlate(unit.get(), xmbNode,
                { pos = [rect.get().l, rect.get().t], dragStartDelay = null, transform = {}, size = plateSize.get() })
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
