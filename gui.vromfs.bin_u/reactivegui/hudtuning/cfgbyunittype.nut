from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { optScale } = require("cfg/cfgOptions.nut")

let config = {
  [TANK] = require("cfg/cfgHudTank.nut"),
  [AIR] = require("cfg/cfgHudAircraft.nut"),
  [SHIP] = require("cfg/cfgHudShip.nut"),
  [SUBMARINE] = require("cfg/cfgHudSubmarine.nut")
}

let reqFields = ["ctor", "defTransform", "editView"]
let cfgByUnitType = {}
let cfgByUnitTypeOrdered = {}
foreach (unitType, tbl in config) {
  foreach (cfgId, cfg in tbl) {
    let missId = reqFields.findvalue(@(id) id not in cfg)
    if (missId != null) {
      logerr($"Missing field {missId} in hudTuningCfg {unitType}/{cfgId}")
      continue
    }

    cfg.id <- cfgId
    cfg.editViewKey <- $"elem_{cfgId}"

    let hasScale = cfg.ctor.getfuncinfos().parameters.len() == 2
    cfg.hasScale <- hasScale
    if (hasScale) {
      let { options = [] } = cfg
      if (!options.contains(optScale))
        cfg.options <- options.insert(0, optScale)
    }
  }
  cfgByUnitType[unitType] <- tbl
  cfgByUnitTypeOrdered[unitType] <- tbl.values().sort(@(a, b) (a?.priority ?? 0) <=> (b?.priority ?? 0))
}


return {
  cfgByUnitType
  cfgByUnitTypeOrdered
}