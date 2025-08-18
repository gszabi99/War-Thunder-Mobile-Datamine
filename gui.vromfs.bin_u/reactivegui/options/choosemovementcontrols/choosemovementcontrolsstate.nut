from "%globalsDarg/darg_library.nut" import *

let isChooseMovementControlsOpened = mkWatched(persist, "isChooseMovementControlsOpened", false)

let onControlsApply = @() isChooseMovementControlsOpened.set(false)

return {
  onControlsApply
  isChooseMovementControlsOpened
  openChooseMovementControls = @() isChooseMovementControlsOpened.set(true)
}
