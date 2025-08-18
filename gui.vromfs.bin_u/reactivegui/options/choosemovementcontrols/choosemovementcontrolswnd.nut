from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { isChooseMovementControlsOpened } = require("%rGui/options/chooseMovementControls/chooseMovementControlsState.nut")
let mkChooseMoveControlsScene = require("%rGui/options/chooseMovementControls/chooseMovementControlsScene.nut")

let close = @() isChooseMovementControlsOpened.set(false)

let mkScene = @() {
  key = {}
  size = flex()
  children = [
    mkChooseMoveControlsScene()
    {
      margin = saBordersRv
      children = backButton(close)
    }
  ]
  animations = wndSwitchAnim
}

registerScene("chooseMovementControls", mkScene, close, isChooseMovementControlsOpened)
