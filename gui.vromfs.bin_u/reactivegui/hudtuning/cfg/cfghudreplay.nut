from "%globalsDarg/darg_library.nut" import *
let { TANK, SHIP, SUBMARINE } = require("%appGlobals/unitConst.nut")
let { needScoreBoard, scoreBoardCfgByType, scoreBoardType } = require("%rGui/hud/scoreBoard.nut")
let { Z_ORDER, mkLTPos, mkCTPos, mkLBPos } = require("%rGui/hudTuning/cfg/hudTuningPkg.nut")
let { mkDollCtor, defHealthSize } = require("%rGui/hud/shipStateModule.nut")
let { xrayModel } = require("%rGui/hud/aircraftStateModule.nut")
let { mkMenuButton } = require("%rGui/hud/menuButton.nut")
let { mkDoll } = require("%rGui/hud/tankStateModule.nut")
let { hudUnitType } = require("%rGui/hudStateExt.nut")


let dollPosX = clamp(saSize[0] / 2 - hdpx(460), hdpx(420), hdpx(540))

return {
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
}
