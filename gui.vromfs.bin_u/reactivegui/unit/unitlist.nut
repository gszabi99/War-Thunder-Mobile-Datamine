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

let mkPlatoonUnitsList = @(baseUnit) Computed(function() {
  let { name = "", platoonUnits = [] } = baseUnit.get()
  return platoonUnits.len() != 0
    ? [ { name, reqLevel = 0 } ].extend(platoonUnits)
    : []
})

let mkUnitToShowCommon = @(baseUnit, selectedUnitId) Computed(function() {
  let unitName = selectedUnitId.get()
  return baseUnit.get() == null ? null
    : unitName == baseUnit.get().name || unitName == null || unitName == "" ? baseUnit.get()
    : baseUnit.get().__merge({ name = unitName })
})

return {
  mkBaseUnit
  mkPlatoonUnitsList
  mkUnitToShowCommon
}