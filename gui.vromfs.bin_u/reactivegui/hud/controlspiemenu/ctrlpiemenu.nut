from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/controlsPieMenu/ctrlPieState.nut" import ctrlPieCfg, isCtrlPieStickActive, ctrlPieSelectedIdx
from "%rGui/hud/pieMenu.nut" import mkPieMenu, defaultPieMenuParams
from "%rGui/hud/stickState.nut" import STICK


let ctrlMsgPieComp = mkPieMenu(ctrlPieCfg, ctrlPieSelectedIdx, defaultPieMenuParams.__merge({ pieActiveStick = STICK.RIGHT }))

function ctrlPieMenu() {
  let res = { watch = isCtrlPieStickActive }
  return isCtrlPieStickActive.get()
    ? res.__update(ctrlMsgPieComp)
    : res
}

return ctrlPieMenu
