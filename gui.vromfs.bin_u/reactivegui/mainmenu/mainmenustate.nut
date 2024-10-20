from "%globalsDarg/darg_library.nut" import *
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { scenesOrder } = require("%rGui/navState.nut")

let isMainMenuAttached = Watched(false)
let isMainMenuTopScene = Computed(@() isMainMenuAttached.get() && !scenesOrder.get().len())
let isInMenuNoModals = Computed(@() isMainMenuTopScene.get() && !hasModalWindows.get())
let isUnitsWndAttached = Watched(false)
let isUnitsWndOpened = mkWatched(persist, "isOpened", false)

return {
  isMainMenuAttached
  isInMenuNoModals
  isMainMenuTopScene
  isUnitsWndAttached
  isUnitsWndOpened
}