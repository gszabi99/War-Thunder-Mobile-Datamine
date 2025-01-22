from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { campUnitsCfg, campMyUnits, playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { ovrHangarAddon } = require("%appGlobals/updater/addons.nut")
let { curCampaign, blueprints } = require("%appGlobals/pServer/campaign.nut")
let { clearFilters } = require("%rGui/unit/unitsFilterState.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { needToShowHiddenUnitsDebug } = require("%rGui/unit/debugUnits.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")

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

let unitsMaxRank = Computed(@() campUnitsCfg.get().map(@(v) v.rank).reduce(@(a, b) max(a, b)) ?? 0)
let unitsMaxStarRank = Computed(@() campUnitsCfg.get().map(@(v) v.starRank).reduce(@(a, b) max(a, b)) ?? 0)

let mkAllTreeUnits = @() Computed(@() needToShowHiddenUnitsDebug.get()
  ? campUnitsCfg.get()
    .map(@(u, id) campMyUnits.get()?[id] ?? u)
  : campUnitsCfg.get()
    .filter(@(u) (!u?.isHidden && u.name in releasedUnits.get())
      || u.name in campMyUnits.get()
      || (blueprints.get()?[u.name] ?? 0) > 0)
    .map(@(u, id) campMyUnits.get()?[id] ?? u))

function mapUnitsByCountryGroup(units) {
  let res = {}
  foreach (unit in units) {
    let { country, rank } = unit
    let countriesGroup = countryGroup?[country] ?? defaultCountryGroup
    if (countriesGroup not in res)
      res[countriesGroup] <- {}
    if (rank not in res[countriesGroup])
      res[countriesGroup][rank] <- []
    res[countriesGroup][rank].append(unit)
  }
  return res
}

function getColumnsCfg(unitsByGroup, maxRank) {
  let cfg = { total = 0 }
  for (local i = 1; i <= maxRank; i++) {
    let unitsInRank = unitsByGroup
      .reduce(@(res, unitsByCountry) max(res, unitsByCountry?[i].len() ?? 0), 0)
    cfg[i] <- cfg.total
    cfg.total += unitsInRank
  }
  return cfg
}

let unitsTreeBg = Computed(function() {
  let addonHangar = ovrHangarAddon?.hangarPath
  return bgByHangar?[curCampaign.get()][addonHangar] ?? $"{curCampaign.get()}_blur_bg.avif"
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
function openUnitsTreeAtUnit(unitName) {
  openUnitsTreeWnd()
  curSelectedUnit.set(unitName)
}

return {
  isUnitsTreeOpen
  isUnitsTreeAttached
  unitsTreeOpenRank
  closeUnitsTreeWnd
  openUnitsTreeWnd
  openUnitsTreeAtCurRank
  openUnitsTreeAtUnit

  unitsMaxRank
  unitsMaxStarRank
  unitsTreeBg

  mkAllTreeUnits
  mapUnitsByCountryGroup
  getColumnsCfg

  countriesCfg
  countriesRows
}
