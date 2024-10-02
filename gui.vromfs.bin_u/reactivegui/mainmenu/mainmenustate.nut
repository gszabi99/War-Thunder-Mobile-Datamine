from "%globalsDarg/darg_library.nut" import *
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { scenesOrder } = require("%rGui/navState.nut")

let isMainMenuAttached = Watched(false)
let isInMenuNoModals = Computed(@() isMainMenuAttached.get()
  && !hasModalWindows.get()
  && !scenesOrder.get().len())
let isUnitsWndAttached = Watched(false)
let isUnitsWndOpened = mkWatched(persist, "isOpened", false)

return {
  isMainMenuAttached
  isInMenuNoModals
  isUnitsWndAttached
  isUnitsWndOpened
}