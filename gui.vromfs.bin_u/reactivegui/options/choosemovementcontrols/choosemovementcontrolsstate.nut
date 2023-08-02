from "%globalsDarg/darg_library.nut" import *

let isChooseMovementControlsOpened = mkWatched(persist, "isChooseMovementControlsOpened", false)

let onControlsApply = @() isChooseMovementControlsOpened(false)

return {
  onControlsApply
  isChooseMovementControlsOpened
  openChooseMovementControls = @() isChooseMovementControlsOpened(true)
}
