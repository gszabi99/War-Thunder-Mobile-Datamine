from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let backButton = require("%rGui/components/backButton.nut")
let { isChooseMovementControlsOpened } = require("chooseMovementControlsState.nut")
let chooseMovementControlsScene = require("chooseMovementControlsScene.nut")

let close = @() isChooseMovementControlsOpened(false)

let wnd = {
  key = {}
  size = flex()
  children = [
    chooseMovementControlsScene
    {
      margin = saBordersRv
      children = backButton(close)
    }
  ]
  animations = wndSwitchAnim
}

registerScene("chooseMovementControls", wnd, close, isChooseMovementControlsOpened)
