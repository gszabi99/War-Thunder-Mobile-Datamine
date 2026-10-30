from "%globalsDarg/darg_library.nut" import *
from "%rGui/clans/clanCfg.nut" import LOCATION, LANGUAGE, MEMBERS, clanLocations, languagesCfg, languageValues, TYPE, AVAILABILITY
from "%appGlobals/clanConsts.nut" import PRIVACY_OPEN, PRIVACY_REQUEST, AVAILABILITY_FULL, AVAILABILITY_NOT_FULL


let clanFilterW = mkWatched(persist, "clanFilter", {})
let mkSetFilterValue = @(id) @(value) clanFilterW.mutate(@(v) v[id] <- value)
let resetFilter = @() clanFilterW.set({})

let filters = [
  {
    id = TYPE
    values = [null, PRIVACY_OPEN, PRIVACY_REQUEST]
    valToString = @(v) v ? $"clans/type/{v}": "filter/type/any"
    btnMinWidth = hdpx(250)
    defValue = null
  },
  {
    id = LOCATION
    values = [null].extend(clanLocations.get())
    valToString = @(v) v ? $"region/{v}" : "filter/location/any"
    btnMinWidth = hdpx(260)
    col = 4
    defValue = null
  },
  {
    id = LANGUAGE
    values = languageValues.get()
    col = 5
    btnMinWidth = hdpx(200)
    valToString = @(v) v ? languagesCfg?[v].title : "filter/language/any"
    textToUpper = false
    defValue = null
  },
  {
    id = MEMBERS
    values = [0, 5, 10, 15, 20, 25]
    valToString = @(v) $"{v}+"
    col = 3
    btnMinWidth = hdpx(110)
    defValue = 0
    fullLocTitle = "filters/members/title"
  },
  {
    id = AVAILABILITY
    values = [null, AVAILABILITY_FULL, AVAILABILITY_NOT_FULL]
    valToString = @(v) v ? $"filter/availability/{v}" : "filter/availability/any"
    btnMinWidth = hdpx(250)
    defValue = null
  },
].map(@(v) v.__update({
  locTitle = $"filters/{v.id}"
}))

languageValues.subscribe(function(v) {
  let langFilter = filters.findvalue(@(cfg) cfg.id == LANGUAGE)
  if (langFilter)
    langFilter.values <- v
})

clanLocations.subscribe(function(v) {
  let locations = filters.findvalue(@(cfg) cfg.id == LOCATION)
  if (locations)
    locations.values <- [null].extend(v)
})

let clanFilterComp = Computed(function() {
  let curFilter = {}
  foreach(f in filters) {
    curFilter[f.id] <- clanFilterW.get()?[f.id] ?? f.defValue
  }
  return curFilter
})

return {
  filters
  clanFilterComp
  resetFilter
  mkSetFilterValue
}
