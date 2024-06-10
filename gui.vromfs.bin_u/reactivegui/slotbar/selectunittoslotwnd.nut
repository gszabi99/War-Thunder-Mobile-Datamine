from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow, hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { msgBoxBg, msgBoxHeaderWithClose } = require("%rGui/components/msgBox.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { slotBarSelectWnd } = require("slotBar.nut")
let { selectedUnitToSlot, slots } = require("slotBarState.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")


let WND_UID = "selectUnitToSlot"

let needSelectUnitResearch = keepref(Computed(@() selectedUnitToSlot.get() != null))

let function close() {
  selectedUnitToSlot.set(null)
  removeModalWindow(WND_UID)
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = flex()
  onClick = close
  children = msgBoxBg.__merge({
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      msgBoxHeaderWithClose(loc("slotbar/chooseSlot", { unit = loc(getUnitLocId(curSelectedUnit.get())) }),
        close,
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, buttonsHGap]
        })
      {
        padding = buttonsHGap
        gap = buttonsHGap
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = slotBarSelectWnd
      }
    ]
  })
  animations = wndSwitchAnim
}))

function openWndIfCan() {
  if (needSelectUnitResearch.get()
      && !hasModalWindows.get()
      && !isInBattle.get()
      && slots.get().len() > 0)
    openImpl()
}

if (needSelectUnitResearch.get())
  openWndIfCan()
needSelectUnitResearch.subscribe(@(v) v ? openWndIfCan() : removeModalWindow(WND_UID))

return openWndIfCan
