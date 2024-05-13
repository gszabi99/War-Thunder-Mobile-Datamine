from "%globalsDarg/darg_library.nut" import *
let { allUnitsCfg, myUnits, playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { ovrHangarAddon } = require("%appGlobals/updater/addons.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { filters, filterCount } = require("%rGui/unit/unitsFilterPkg.nut")
let { clearFilters } = require("%rGui/unit/unitsFilterState.nut")


let bgByCampaign = {
  tanks = "tank_blur_bg.avif"
  ships = "ship_blur_bg.avif"
  air = "air_blur_bg.avif"
}

let bgByHangar = {
  tanks = {
    ["config/hangar_field_ny.blk"] = "tank_blur_bg_ny.avif"
  }
}

let countriesCfg = [
  ["country_usa", "country_israel"],
  ["country_germany", "country_italy"],
  ["country_ussr", "country_china"],
  ["country_uk", "country_france", "country_sweden"],
  ["country_japan"],
]
let countryGroup = countriesCfg.reduce(@(r, list, rowIdx)
  list.reduce(@(res, country) res.rawset(country, rowIdx), r), {})
let defaultCountryGroup = 4
let countriesRows = countriesCfg.len()

let isUnitsTreeOpen = mkWatched(persist, "isUnitsTreeOpen", false)
let isUnitsTreeAttached = Watched(false)
let unitsTreeOpenRank = Watched(null)

let unitsMaxRank = Computed(@() allUnitsCfg.value.map(@(v) v.rank).reduce(@(a, b) max(a, b)) ?? 0)
let unitsMaxStarRank = Computed(@() allUnitsCfg.value.map(@(v) v.starRank).reduce(@(a, b) max(a, b)) ?? 0)

let unitsMapped = Computed(function() {
  let res = {}
  let visibleCountries = {}
  local allUnits = allUnitsCfg.value
    .filter(@(u) !u?.isHidden || u.name in myUnits.value)
    .map(@(u, id) myUnits.value?[id] ?? u)

  if (filterCount.get() > 0)
    foreach (f in filters) {
      let value = f.value.get()
      if (value != null)
        allUnits = allUnits.filter(@(u) f.isFit(u, value))
    }

  for (local g = 0; g < countriesRows; g++) {
    res[g] <- {}
    for (local r = 1; r <= unitsMaxRank.value; r++)
      res[g][r] <- []
  }

  foreach (unit in allUnits) {
    let { country, rank } = unit
    visibleCountries[country] <- true
    let countriesGroup = countryGroup?[country] ?? defaultCountryGroup
    res[countriesGroup][rank].append(unit)
  }

  return {
    units = res.filter(@(v) v.findindex(@(u) u.len() > 0) != null)
    visibleCountries
  }
})

let columnsCfg = Computed(function() {
  let res = { "0" : 0 }
  for (local i = 1; i <= unitsMaxRank.value + 1; i++){
    let unitsInRank = unitsMapped.value.units
      .map(@(unitsByCountry) unitsByCountry?[i].len() ?? 0)
      .reduce(@(a, b) max(a, b))
        ?? 0
    res[i] <- res["0"]
    res["0"] += unitsInRank // total columns amount
  }
  return res
})

let unitsTreeBg = Computed(function() {
  let addonHangar = ovrHangarAddon?.hangarPath
  return bgByHangar?[curCampaign.get()][addonHangar] ?? bgByCampaign?[curCampaign.get()]
})

let closeUnitsTreeWnd = @() isUnitsTreeOpen.set(false)
function openUnitsTreeWnd() {
  clearFilters()
  isUnitsTreeOpen.set(true)
}
function openUnitsTreeAtCurRank() {
  openUnitsTreeWnd()
  unitsTreeOpenRank.set(playerLevelInfo.get().level + 1)
}

return {
  isUnitsTreeOpen
  isUnitsTreeAttached
  unitsTreeOpenRank
  closeUnitsTreeWnd
  openUnitsTreeWnd
  openUnitsTreeAtCurRank

  unitsMapped
  unitsMaxRank
  unitsMaxStarRank
  unitsTreeBg

  countriesCfg
  countriesRows
  columnsCfg
}
