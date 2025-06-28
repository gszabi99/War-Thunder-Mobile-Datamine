from "%globalsDarg/darg_library.nut" import *
let { baseUnit } = require("%rGui/unitDetails/unitDetailsState.nut")


let openForUnit = mkWatched(persist, "openForUnit", null)
let openCount = Watched(openForUnit.get() == null ? 0 : 1)
let unitCustomOpenCount = Computed(@() openForUnit.get() == null || openForUnit.get() != baseUnit.get()?.name ? 0
  : openCount.get())

function openUnitCustom() {
  openForUnit.set(baseUnit.get()?.name)
  openCount.set(openCount.get() + 1)
}

function closeUnitCustom() {
  openForUnit.set(null)
  openCount.set(0)
}

baseUnit.subscribe(function(u) {
  if (u?.name != openForUnit.get())
    closeUnitCustom()
})

return {
  openForUnit
  unitCustomOpenCount
  openUnitCustom
  closeUnitCustom
}
