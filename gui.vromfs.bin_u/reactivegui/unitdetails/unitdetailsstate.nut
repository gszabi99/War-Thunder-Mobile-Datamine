from "%globalsDarg/darg_library.nut" import *
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { setCustomHangarUnit, resetCustomHangarUnit } = require("%rGui/unit/hangarUnit.nut")


let curSelectedUnitId = Watched(null)
let curSelectedUnitSkin = Watched(null)
let openUnitOvr = mkWatched(persist, "openUnitOvr", null)
let isWindowAttached = Watched(false)

let baseUnit = Computed(function() {
  let { name = null, canShowOwnUnit = true} = openUnitOvr.value
  local res = canShowOwnUnit ? myUnits.value?[name] ?? serverConfigs.value?.allUnits[name]
    : serverConfigs.value?.allUnits[name]
  if (res == null)
    return res
  res = res.__merge(openUnitOvr.value)
  if (res?.isUpgraded ?? false)
    res.__update(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {})
  return res
})

let platoonUnitsList = Computed(function() {
  let { name = "", platoonUnits = [] } = baseUnit.value
  return platoonUnits.len() != 0
    ? [ { name, reqLevel = 0 } ].extend(platoonUnits)
    : []
})

let unitToShowCommon = Computed(function() {
  if (baseUnit.value == null)
    return null
  let unitName = curSelectedUnitId.value
  if (unitName == baseUnit.value.name || unitName == null || unitName == "")
    return baseUnit.value
  return baseUnit.value.__merge({ name = unitName })
})
let unitToShow = Computed(@() unitToShowCommon.get() == null || curSelectedUnitSkin.get() == null
  ? unitToShowCommon.get()
  : unitToShowCommon.get().__merge({
      currentSkins = (unitToShowCommon.get()?.currentSkins ?? {})
        .__merge({ [unitToShowCommon.get().name] = curSelectedUnitSkin.get() })
    }))
unitToShow.subscribe(function(unit) {
  if (unit != null)
    setCustomHangarUnit(unit)
  else
    resetCustomHangarUnit()
})

return {
  curSelectedUnitId
  curSelectedUnitSkin
  openUnitOvr
  closeUnitDetailsWnd = @() openUnitOvr.set(null)
  baseUnit
  platoonUnitsList
  unitToShow
  isWindowAttached
}