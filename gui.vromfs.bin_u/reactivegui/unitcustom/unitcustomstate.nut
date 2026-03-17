from "%globalsDarg/darg_library.nut" import *
let { baseUnit, isOwnUnit } = require("%rGui/unitDetails/unitDetailsState.nut")
let { showDecalInfoWnd } = require("%rGui/unitCustom/unitCustomDecalInfoModalWnd.nut")


enum SECTION_IDS {
  SKINS = "skins"
  DECALS = "decals"
}

let selSectionId = mkWatched(persist, "unitCustomSelSectionId", null)
let openForUnit = mkWatched(persist, "openForUnit", null)
let openCount = Watched(openForUnit.get() == null ? 0 : 1)
let unitCustomOpenCount = Computed(@() openForUnit.get() == null || openForUnit.get() != baseUnit.get()?.name ? 0
  : openCount.get())

let sectionsList = Computed(@() isOwnUnit.get() ? [SECTION_IDS.SKINS, SECTION_IDS.DECALS] : [SECTION_IDS.SKINS])

let curSelectedSectionId = Computed(@() (!selSectionId.get() || !sectionsList.get().contains(selSectionId.get()))
  ? sectionsList.get()[0]
  : selSectionId.get())

selSectionId.subscribe(@(v) v == SECTION_IDS.DECALS && showDecalInfoWnd())

function openUnitCustom() {
  openForUnit.set(baseUnit.get()?.name)
  openCount.set(openCount.get() + 1)
}

function closeUnitCustom() {
  openForUnit.set(null)
  selSectionId.set(null)
  openCount.set(0)
}

baseUnit.subscribe(@(u) u?.name != openForUnit.get() ? closeUnitCustom() : null)

return {
  openForUnit
  unitCustomOpenCount
  openUnitCustom
  closeUnitCustom
  curSelectedSectionId
  selSectionId
  sectionsList
  SECTION_IDS
}
