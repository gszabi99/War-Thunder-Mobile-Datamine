from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%rGui/unit/hangarUnit.nut" import setCustomHangarUnit
from "%rGui/unit/unitList.nut" import mkBaseUnit


let curSelectedUnitSkin = Watched(null)
let openUnitOvr = mkWatched(persist, "openUnitOvr", null)
let unitDetailsOpenCount = Watched(openUnitOvr.get() == null ? 0 : 1)
let isWindowAttached = Watched(false)
let isCustomizationWndAttached = Watched(false)
let isOwnUnit = Computed(@() (openUnitOvr.get()?.canShowOwnUnit ?? true) && openUnitOvr.get()?.name in campMyUnits.get())

let baseUnit = mkBaseUnit(openUnitOvr)
let unitToShow = Computed(@() !isWindowAttached.get() && !isCustomizationWndAttached.get() ? null
  : baseUnit.get() == null || curSelectedUnitSkin.get() == null ? baseUnit.get()
  : baseUnit.get().__merge({ skin = curSelectedUnitSkin.get() }))

unitToShow.subscribe(@(u) u != null ? setCustomHangarUnit(u) : null)

function openUnitDetailsWnd(unitOvr = {}) {
  openUnitOvr.set(unitOvr)
  unitDetailsOpenCount.set(unitDetailsOpenCount.get() + 1)
}

function closeUnitDetailsWnd() {
  openUnitOvr.set(null)
  unitDetailsOpenCount.set(0)
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