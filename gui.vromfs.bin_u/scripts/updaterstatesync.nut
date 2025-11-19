from "%scripts/dagui_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%appGlobals/updater/addonsState.nut" import unitSizes, isUnitSizesActual, UNIT_SIZES_EVENT_ID

function onGetUnitsSizes(evt) {
  unitSizes.set(unitSizes.get().__merge(evt))
  isUnitSizesActual.set(true)
}
eventbus_subscribe(UNIT_SIZES_EVENT_ID, onGetUnitsSizes)
unitSizes.whiteListMutatorClosure(onGetUnitsSizes)
