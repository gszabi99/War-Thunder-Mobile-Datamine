from "%globalScripts/logs.nut" import *
let { Computed } = require("frp")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let unitNameRemapByCampaign = {
  ships_new = { ships = true }
  tanks_new = { tanks = true }
}

let allMainUnitsByPlatoon = Computed(function() {
  let cfg = serverConfigs.get()?.allUnits ?? {}
  let res = {}
  foreach (unit in cfg)
    foreach (pu in unit.platoonUnits)
      res[pu.name] <- unit
  res.__update(cfg)
  return res
})

function getPlatoonUnitCfg(name, allMain, campaign) {
  let main = allMain?[name]
  let unitCfg = (!main || main.name == name) ? main
    : main.__merge(main.platoonUnits.findvalue(@(pu) pu.name == name) ?? { name })
  if (!unitNameRemapByCampaign?[campaign][unitCfg?.campaign])
    return unitCfg
  let nameNew = $"{name}_nc"
  let mainNc = allMain?[nameNew]
  let unitCfgNc = (!mainNc || mainNc.name == nameNew) ? mainNc
    : mainNc.__merge({ name = nameNew })
  return unitCfgNc ?? unitCfg
}

return {
  allMainUnitsByPlatoon
  getPlatoonUnitCfg
  getPlatoonUnitCfgNonUpdatable = @(name) getPlatoonUnitCfg(name, allMainUnitsByPlatoon.get(), curCampaign.get())
}
