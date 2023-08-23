from "%globalsDarg/darg_library.nut" import *
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")

let isMainMenuAttached = Watched(false)
let isInMenuNoModals = Computed(@() isMainMenuAttached.value && !hasModalWindows.value)
let isUnitsWndAttached = Watched(false)
let isUnitsWndOpened = mkWatched(persist, "isOpened", false)

return {
  isMainMenuAttached
  isInMenuNoModals
  isUnitsWndAttached
  isUnitsWndOpened
}