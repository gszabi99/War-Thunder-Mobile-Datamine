from "%globalsDarg/darg_library.nut" import *
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { setCustomHangarUnit, resetCustomHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { mkBaseUnit, mkPlatoonUnitsList, mkUnitToShowCommon } = require("%rGui/unit/unitList.nut")


let curSelectedUnitId = Watched(null)
let curSelectedUnitSkin = Watched(null)
let openUnitOvr = mkWatched(persist, "openUnitOvr", null)
let unitDetailsOpenCount = Watched(openUnitOvr.get() == null ? 0 : 1)
let isWindowAttached = Watched(false)
let isCustomizationWndAttached = Watched(false)
let isOwnUnit = Computed(@() (openUnitOvr.get()?.canShowOwnUnit ?? true) && openUnitOvr.get()?.name in campMyUnits.get())

let function setUnit(unit) {
  if (unit != null)
    setCustomHangarUnit(unit)
  else
    resetCustomHangarUnit()
}

let baseUnit = mkBaseUnit(openUnitOvr)
let unitToShowCommon = mkUnitToShowCommon(baseUnit, curSelectedUnitId)
let unitToShow = Computed(@() unitToShowCommon.get() == null || curSelectedUnitSkin.get() == null
  ? unitToShowCommon.get()
  : unitToShowCommon.get().__merge({
      currentSkins = (unitToShowCommon.get()?.currentSkins ?? {})
        .__merge({ [unitToShowCommon.get().name] = curSelectedUnitSkin.get() })
    }))
unitToShow.subscribe(function(u) {
  if (isWindowAttached.get() || isCustomizationWndAttached.get())
    setUnit(u)
})
isWindowAttached.subscribe(@(v) !v ? null : setUnit(unitToShow.get()))

function openUnitDetailsWnd(unitOvr = {}) {
  openUnitOvr.set(unitOvr)
  unitDetailsOpenCount.set(unitDetailsOpenCount.get() + 1)
}

function closeUnitDetailsWnd() {
  openUnitOvr.set(null)
  unitDetailsOpenCount.set(0)
  resetCustomHangarUnit()
}

return {
  curSelectedUnitId
  curSelectedUnitSkin
  openUnitOvr
  unitDetailsOpenCount
  openUnitDetailsWnd
  closeUnitDetailsWnd
  baseUnit
  platoonUnitsList = mkPlatoonUnitsList(baseUnit)
  unitToShow
  isWindowAttached
  isCustomizationWndAttached
  isOwnUnit
}