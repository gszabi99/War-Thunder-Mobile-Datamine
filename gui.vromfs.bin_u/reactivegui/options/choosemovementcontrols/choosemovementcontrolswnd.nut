from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let backButton = require("%rGui/components/backButton.nut")
let { isChooseMovementControlsOpened } = require("chooseMovementControlsState.nut")
let mkChooseMoveControlsScene = require("chooseMovementControlsScene.nut")

let close = @() isChooseMovementControlsOpened(false)

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
