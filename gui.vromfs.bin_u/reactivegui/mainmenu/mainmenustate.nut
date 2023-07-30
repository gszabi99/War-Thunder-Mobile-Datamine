from "%globalsDarg/darg_library.nut" import *
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")

let isMainMenuAttached = Watched(false)
let isInMenuNoModals = Computed(@() isMainMenuAttached.value && !hasModalWindows.value)

return {
  isMainMenuAttached
  isInMenuNoModals
}