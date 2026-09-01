from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/cameraPieMenu/cameraPieState.nut" import cameraPieCfg, isCameraPieStickActive, cameraPieSelectedIdx
from "%rGui/hud/pieMenu.nut" import mkPieMenu, defaultPieMenuParams
from "%rGui/hud/stickState.nut" import STICK


let cameraMsgPieComp = mkPieMenu(cameraPieCfg, cameraPieSelectedIdx,
  defaultPieMenuParams.__merge({ pieIconSizeMul = 0.4, pieActiveStick = STICK.RIGHT }))

function cameraPieMenu() {
  let res = { watch = isCameraPieStickActive }
  return isCameraPieStickActive.get()
    ? res.__update(cameraMsgPieComp)
    : res
}

return cameraPieMenu
