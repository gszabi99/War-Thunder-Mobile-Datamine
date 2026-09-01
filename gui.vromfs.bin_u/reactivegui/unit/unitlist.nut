from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs


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