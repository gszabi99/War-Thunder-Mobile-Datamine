from "%globalsDarg/darg_library.nut" import *
let { mkPieMenu, defaultPieMenuParams } = require("%rGui/hud/pieMenu.nut")
let { cameraPieCfg, isCameraPieStickActive, cameraPieSelectedIdx } = require("%rGui/hud/cameraPieMenu/cameraPieState.nut")
let { STICK } = require("%rGui/hud/stickState.nut")

let cameraMsgPieComp = mkPieMenu(cameraPieCfg, cameraPieSelectedIdx,
  defaultPieMenuParams.__merge({ pieIconSizeMul = 0.4, pieActiveStick = STICK.RIGHT }))

function cameraPieMenu() {
  let res = { watch = isCameraPieStickActive }
  return isCameraPieStickActive.get()
    ? res.__update(cameraMsgPieComp)
    : res
}

return cameraPieMenu
