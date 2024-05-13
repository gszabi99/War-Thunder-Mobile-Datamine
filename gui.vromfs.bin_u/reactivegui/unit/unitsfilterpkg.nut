from "%globalsDarg/darg_library.nut" import *
let { optName, optCountry, optMRank, optStatus, optUnitClass, clearFilters
} = require("%rGui/unit/unitsFilterState.nut")
let mkUnitsFilter = require("%rGui/unit/mkUnitsFilter.nut")
let modalPopupWnd = require("%rGui/components/modalPopupWnd.nut")
let { availableUnitsList } = require("%rGui/unit/unitsWndState.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")


let isFiltersVisible = Watched(false)
let filters = [optName, optStatus, optUnitClass, optMRank, optCountry]
let filtersTreeNodes = [optName, optStatus, optUnitClass, optMRank]
let activeFilters = Watched(0)
let filterCount = Watched(0)

const FILTER_UID = "units_filter"
let closeFilters = @() modalPopupWnd.remove(FILTER_UID)
let openFilters = @(event, isTreeNodes, ovr = {})
  modalPopupWnd.add(event.targetRect, {
    uid = FILTER_UID
    rendObj = ROBJ_BOX
    fillColor = 0xD0000000
    borderColor = 0xFFE1E1E1
    borderWidth = hdpx(3)
    padding = hdpx(20)
    popupValign = ALIGN_BOTTOM
    popupHalign = ALIGN_LEFT
    children = mkUnitsFilter(isTreeNodes ? filtersTreeNodes : filters, availableUnitsList, closeFilters, clearFilters)
    // OFFSET
    popupOffset = hdpx(20)
    hotkeys = [[btnBEscUp, closeFilters]]
    onAttach = @() isFiltersVisible(true)
    onDetach = @() isFiltersVisible(false)
  }.__merge(ovr))

let filterStateFlags = Watched(0)
let getFiltersText = @(count) count <= 0 ? loc("showFilters") : loc("activeFilters", { count })


function countActiveFilters() {
  filterCount.set(filterCount.get() + 1)
  return activeFilters(filters.reduce(function(res, f) {
    let { value } = f.value
    if (value != null && value != ""
        && (type(value) != "table" || value.len() < f.allValues.value.len()))
      res++
    return res
  }, 0))
}
countActiveFilters()
foreach (f in filters) {
  f.value.subscribe(@(_) countActiveFilters())
  f?.allValues.subscribe(@(_) countActiveFilters())
}

return {
  isFiltersVisible
  filterStateFlags
  activeFilters
  filterCount
  filters
  getFiltersText
  openFilters
}
