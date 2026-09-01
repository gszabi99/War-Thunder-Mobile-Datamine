from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *

let config = {
  [TANK] = require("%rGui/hudTuning/cfg/cfgHudTank.nut"),
  [AIR] = require("%rGui/hudTuning/cfg/cfgHudAircraft.nut"),
  [SHIP] = require("%rGui/hudTuning/cfg/cfgHudShip.nut"),
  [SUBMARINE] = require("%rGui/hudTuning/cfg/cfgHudSubmarine.nut"),
  [SAILBOAT] = require("%rGui/hudTuning/cfg/cfgHudSailboat.nut"),
  [WALKER] = require("%rGui/hudTuning/cfg/cfgHudWalker.nut"),
}

let reqFields = ["ctor", "defTransform", "editView"]
let cfgByUnitType = {}
let cfgByUnitTypeOrdered = {}
foreach (unitType, tbl in config) {
  foreach (cfgId, cfg in tbl) {
    let missId = reqFields.findvalue(@(id) id not in cfg)
    if (missId != null)
      logerr($"Missing field {missId} in hudTuningCfg {unitType}/{cfgId}")
    if (cfg?.id != cfgId)
      logerr($"Not inited hudTuningCfg elem {unitType}/{cfgId}")
  }
  cfgByUnitType[unitType] <- tbl
  cfgByUnitTypeOrdered[unitType] <- tbl.values().sort(@(a, b) (a?.priority ?? 0) <=> (b?.priority ?? 0))
}


return {
  cfgByUnitType
  cfgByUnitTypeOrdered
}