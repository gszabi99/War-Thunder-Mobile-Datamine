from "%globalsDarg/darg_library.nut" import *
let { mkPieMenu } = require("%rGui/hud/pieMenu.nut")
let { ctrlPieCfg, isCtrlPieStickActive, ctrlPieSelectedIdx } = require("ctrlPieState.nut")

let ctrlMsgPieComp = mkPieMenu(ctrlPieCfg, ctrlPieSelectedIdx)

function ctrlPieMenu() {
  let res = { watch = isCtrlPieStickActive }
  return isCtrlPieStickActive.get()
    ? res.__update(ctrlMsgPieComp)
    : res
}

return ctrlPieMenu
