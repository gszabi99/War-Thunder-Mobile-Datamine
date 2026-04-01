from "%globalsDarg/darg_library.nut" import *
let { currentTankMoveCtrlType, currentWalkerMoveCtrlType } = require("%rGui/options/chooseMovementControls/groundMoveControlType.nut")


let orderByFirstVal = {
  stick         = [ "stick", "stick_static", "arrows" ]
  stick_static  = [ "stick_static", "stick", "arrows" ]
  arrows        = [ "arrows", "stick", "stick_static" ]
}

let isChooseMovementControlsOpened = mkWatched(persist, "isChooseMovementControlsOpened", false)
let isChooseWalkerMovementControlsOpened = mkWatched(persist, "isChooseWalkerMovementControlsOpened", false)

function closeChooseMovementControls() {
  isChooseMovementControlsOpened.set(false)
  isChooseWalkerMovementControlsOpened.set(false)
}

let getCurCtrlTypeW = @() isChooseMovementControlsOpened.get()
    ? currentTankMoveCtrlType
  : isChooseWalkerMovementControlsOpened.get()
    ? currentWalkerMoveCtrlType
  : null

function applyCtrlType(v) {
  let curCtrlTypeW = getCurCtrlTypeW()
  if (curCtrlTypeW != null) {
    curCtrlTypeW.set(v)
    closeChooseMovementControls()
  }
}

function reorderList(list, valToPlaceFirst) {
  return (orderByFirstVal?[valToPlaceFirst] ?? orderByFirstVal.stick)
    .filter(@(v) list.contains(v))
}

return {
  reorderList
  applyCtrlType
  getCurCtrlTypeW
  isChooseMovementControlsOpened
  isChooseWalkerMovementControlsOpened
  closeChooseMovementControls
  openChooseMovementControls = @() isChooseMovementControlsOpened.set(true)
  openChooseWalkerMovementControls = @() isChooseWalkerMovementControlsOpened.set(true)
}
