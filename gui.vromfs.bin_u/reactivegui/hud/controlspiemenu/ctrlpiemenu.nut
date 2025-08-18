from "%globalsDarg/darg_library.nut" import *
let { mkPieMenu, defaultPieMenuParams } = require("%rGui/hud/pieMenu.nut")
let { ctrlPieCfg, isCtrlPieStickActive, ctrlPieSelectedIdx } = require("%rGui/hud/controlsPieMenu/ctrlPieState.nut")
let { STICK } = require("%rGui/hud/stickState.nut")

let ctrlMsgPieComp = mkPieMenu(ctrlPieCfg, ctrlPieSelectedIdx, defaultPieMenuParams.__merge({ pieActiveStick = STICK.RIGHT }))

function ctrlPieMenu() {
  let res = { watch = isCtrlPieStickActive }
  return isCtrlPieStickActive.get()
    ? res.__update(ctrlMsgPieComp)
    : res
}

return ctrlPieMenu
