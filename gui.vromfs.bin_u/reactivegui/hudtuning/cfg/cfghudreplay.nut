from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import TANK, SHIP, SUBMARINE
from "%rGui/hud/aircraftStateModule.nut" import xrayModel
from "%rGui/hud/menuButton.nut" import mkMenuButton
from "%rGui/hud/scoreBoard.nut" import needScoreBoard, scoreBoardCfgByType, scoreBoardType
from "%rGui/hud/shipStateModule.nut" import mkDollCtor, defHealthSize
from "%rGui/hud/tankStateModule.nut" import mkDoll
from "%rGui/hudStateExt.nut" import hudUnitType
from "%rGui/hudTuning/cfg/hudTuningPkg.nut" import Z_ORDER, mkLTPos, mkCTPos, mkLBPos
import "%rGui/hudTuning/cfg/initHudTuningCfg.nut" as initHudTuningCfg


let dollPosX = clamp(saSize[0] / 2 - hdpx(460), hdpx(420), hdpx(540))

return initHudTuningCfg({
  menuBtn = {
    ctor = @(scale) mkMenuButton(scale)
    defTransform = mkLTPos([0, 0])
    priority = Z_ORDER.SUPERIOR
  }

  scores = {
    ctor = @(scale) @() {
      watch = scoreBoardType
      children = scoreBoardCfgByType?[scoreBoardType.get()].ctor(scale)
    }
    defTransform = mkCTPos([0, -hdpx(16)])
    isVisibleInBattle = needScoreBoard
  }

  xrayModel = {
    ctor = xrayModel
    defTransform = mkLBPos([hdpx(480), hdpx(30)])
    isVisibleInBattle = Computed(@() hudUnitType.get() != TANK && hudUnitType.get() != SHIP && hudUnitType.get() != SUBMARINE)
  }

  doll = {
    ctor = mkDoll
    defTransform = mkLBPos([hdpx(540), 0])
    isVisibleInBattle = Computed(@() hudUnitType.get() == TANK)
  }

  shipDoll = {
    ctor = mkDollCtor(defHealthSize)
    defTransform = mkLBPos([dollPosX, hdpx(-38)])
    isVisibleInBattle = Computed(@() hudUnitType.get() == SHIP || hudUnitType.get() == SUBMARINE)
  }
})
