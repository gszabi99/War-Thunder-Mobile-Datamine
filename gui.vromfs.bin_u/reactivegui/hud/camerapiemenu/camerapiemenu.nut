from "%globalsDarg/darg_library.nut" import *
let { mkPieMenu } = require("%rGui/hud/pieMenu.nut")
let { cameraPieCfg, isCameraPieStickActive, cameraPieSelectedIdx } = require("cameraPieState.nut")

let cameraMsgPieComp = mkPieMenu(cameraPieCfg, cameraPieSelectedIdx)

function cameraPieMenu() {
  let res = { watch = isCameraPieStickActive }
  return isCameraPieStickActive.get()
    ? res.__update(cameraMsgPieComp)
    : res
}

return cameraPieMenu
