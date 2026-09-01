from "%globalsDarg/darg_library.nut" import *
import "%rGui/components/modalPopupWnd.nut" as modalPopupWnd
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
import "%rGui/unit/mkUnitsFilter.nut" as mkUnitsFilter
from "%rGui/unit/unitsFilterState.nut" import fillFilters


let isFiltersVisible = Watched(false)

const FILTER_UID = "units_filter"
let closeFilters = @() modalPopupWnd.remove(FILTER_UID)
let openFilters = @(event, filters, resetFilters, allUnits, ovr = {})
  modalPopupWnd.add(event.targetRect, {
    uid = FILTER_UID
    rendObj = ROBJ_BOX
    fillColor = 0xD0000000
    borderColor = 0xFFE1E1E1
    borderWidth = hdpx(3)
    padding = hdpx(20)
    popupValign = ALIGN_BOTTOM
    popupHalign = ALIGN_LEFT
    children = mkUnitsFilter(filters, allUnits, closeFilters, resetFilters, fillFilters)
    
    popupOffset = hdpx(20)
    hotkeys = [[btnBEscUp, closeFilters]]
    onAttach = @() isFiltersVisible.set(true)
    onDetach = @() isFiltersVisible.set(false)
  }.__merge(ovr))

let filterStateFlags = Watched(0)
let getFiltersText = @(count) count <= 0 ? loc("showFilters") : loc("activeFilters", { count })

return {
  isFiltersVisible
  filterStateFlags
  getFiltersText
  openFilters
}
