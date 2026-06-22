from "%globalsDarg/darg_library.nut" import *
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


let mkBaseUnit = @(unit) Computed(function() {
  let { name = null, canShowOwnUnit = true } = unit.get()
  local res = canShowOwnUnit ? campMyUnits.get()?[name] ?? serverConfigs.get()?.allUnits[name]
    : serverConfigs.get()?.allUnits[name]
  if (res == null)
    return res
  res = res.__merge(unit.get())
  if (res?.isUpgraded ?? false)
    res.__update(campConfigs.get()?.gameProfile.upgradeUnitBonus ?? {})
  return res
})

return {
  mkBaseUnit
}