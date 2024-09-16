from "%globalScripts/logs.nut" import *
let { Computed } = require("frp")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let allMainUnitsByPlatoon = Computed(function() {
  let cfg = serverConfigs.get()?.allUnits ?? {}
  let res = {}
  foreach (unit in cfg)
    foreach (pu in unit.platoonUnits)
      res[pu.name] <- unit
  res.__update(cfg)
  return res
})

function getPlatoonUnitCfg(name, allMain) {
  let main = allMain?[name]
  if (!main || main.name == name)
    return main
  return main.__merge(main.platoonUnits.findvalue(@(pu) pu.name == name) ?? { name })
}

return {
  allMainUnitsByPlatoon
  getPlatoonUnitCfg
  getPlatoonUnitCfgNonUpdatable = @(name) getPlatoonUnitCfg(name, allMainUnitsByPlatoon.get())
}
