from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { optScale, optVisible } = require("%rGui/hudTuning/cfg/cfgOptions.nut")

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
    if (missId != null) {
      logerr($"Missing field {missId} in hudTuningCfg {unitType}/{cfgId}")
      continue
    }

    cfg.id <- cfgId
    cfg.editViewKey <- $"elem_{cfgId}"

    let paramCount = cfg.ctor.getfuncinfos().parameters.len()
    let hasScale = paramCount >= 2
    cfg.hasScale <- hasScale
    cfg.needId <- paramCount == 3

    let { options = [] } = cfg
    let canHide = cfg?.canHide ?? true

    if (canHide && !options.contains(optVisible))
      options.insert(0, optVisible)
    if (hasScale && !options.contains(optScale))
      options.insert(0, optScale)

    cfg.options <- options
    cfg.canHide <- canHide
  }
  cfgByUnitType[unitType] <- tbl
  cfgByUnitTypeOrdered[unitType] <- tbl.values().sort(@(a, b) (a?.priority ?? 0) <=> (b?.priority ?? 0))
}


return {
  cfgByUnitType
  cfgByUnitTypeOrdered
}