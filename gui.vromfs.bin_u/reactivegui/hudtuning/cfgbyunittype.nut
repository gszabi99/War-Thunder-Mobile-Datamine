from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *

let export = {
  [TANK] = require("cfg/cfgHudTank.nut"),
  [AIR] = require("cfg/cfgHudAircraft.nut"),
  [SHIP] = require("cfg/cfgHudShip.nut"),
  [SUBMARINE] = require("cfg/cfgHudSubmarine.nut")
}

let reqFields = ["ctor", "defTransform", "editView"]
foreach(unitType, list in export)
  foreach(cfgId, cfg in list) {
    let missId = reqFields.findvalue(@(id) id not in cfg)
    if (missId != null)
      logerr($"Missing field {missId} in hudTuningCfg {unitType}/{cfgId}")
    if ("editView" in cfg)
      cfg.editView <- (clone cfg.editView).__merge({ key = $"elem_{cfgId}" })
  }


return export