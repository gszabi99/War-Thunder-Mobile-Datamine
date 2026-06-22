from "%globalsDarg/darg_library.nut" import *
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { setCustomHangarUnit, resetCustomHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { mkBaseUnit } = require("%rGui/unit/unitList.nut")


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
let unitToShow = Computed(@() baseUnit.get() == null || curSelectedUnitSkin.get() == null
  ? baseUnit.get()
  : baseUnit.get().__merge({ skin = curSelectedUnitSkin.get() }))
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
  curSelectedUnitSkin
  openUnitOvr
  unitDetailsOpenCount
  openUnitDetailsWnd
  closeUnitDetailsWnd
  baseUnit
  unitToShow
  isWindowAttached
  isCustomizationWndAttached
  isOwnUnit
}