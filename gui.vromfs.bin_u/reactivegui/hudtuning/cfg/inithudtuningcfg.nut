from "%globalsDarg/darg_library.nut" import *
from "%rGui/hudTuning/cfg/cfgOptions.nut" import optScale, optVisible


function initHudTuningCfg(tbl) {
  foreach (cfgId, cfg in tbl) {
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
  return tbl
}

return initHudTuningCfg