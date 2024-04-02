from "%globalsDarg/darg_library.nut" import *
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { setCustomHangarUnit, resetCustomHangarUnit } = require("%rGui/unit/hangarUnit.nut")


let curSelectedUnitId = Watched(null)
let curSelectedUnitSkin = Watched(null)
let openUnitOvr = mkWatched(persist, "openUnitOvr", null)
let unitDetailsOpenCount = Watched(openUnitOvr.get() == null ? 0 : 1)
let isWindowAttached = Watched(false)

let function setUnit(unit) {
  if (unit != null)
    setCustomHangarUnit(unit)
  else
    resetCustomHangarUnit()
}

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
unitToShow.subscribe(setUnit)
isWindowAttached.subscribe(@(v) !v ? null : setUnit(unitToShow.get()))

function openUnitDetailsWnd(unitOvr = {}) {
  openUnitOvr.set(unitOvr)
  unitDetailsOpenCount.set(unitDetailsOpenCount.get() + 1)
}

function closeUnitDetailsWnd() {
  openUnitOvr.set(null)
  unitDetailsOpenCount.set(0)
}

return {
  curSelectedUnitId
  curSelectedUnitSkin
  openUnitOvr
  unitDetailsOpenCount
  openUnitDetailsWnd
  closeUnitDetailsWnd
  baseUnit
  platoonUnitsList
  unitToShow
  isWindowAttached
}