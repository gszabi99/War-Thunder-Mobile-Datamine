from "%globalsDarg/darg_library.nut" import *
let { OCT_TEXTINPUT, OCT_MULTISELECT } = require("%rGui/options/optCtrlType.nut")
let { getUnitPresentation, unitClassFontIcons } = require("%appGlobals/unitPresentation.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { utf8ToLower } = require("%sqstd/string.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { canBuyUnitsStatus, US_UNKNOWN, US_OWN, US_NOT_FOR_SALE, US_CAN_BUY, US_TOO_LOW_LEVEL
} = require("%appGlobals/unitsState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")


const OPT_MULTISELECT = "multiselect"
const OPT_EDITBOX = "editbox"

let statusLoc = {
  [US_OWN] = "options/unitOwn",
  [US_CAN_BUY] = "options/unitCanBuy",
  [US_TOO_LOW_LEVEL] = "options/unitNeedLevel",
  [US_NOT_FOR_SALE] = "options/unitNotForSale",
}

let curFilters = mkWatched(persist, "curFilters", {})
let mkValue = @(id, defValue = null) Computed(@() curFilters.value?[id] ?? defValue)
let saveValue = @(id, value) curFilters.mutate(@(f) f[id] <- value)
let mkSetValue = @(id) @(value) saveValue(id, value)

curCampaign.subscribe(@(_) curFilters({}))

let mkListToggleValue = @(id, allValuesW) function toggleValue(value, isChecked) {
  local res = curFilters.value?[id]
  if (res == null) {
    res = {}
    allValuesW.value.each(@(v) res[v] <- true)
  }
  if ((value in res) == isChecked)
    return
  res = clone res
  if (isChecked)
    res[value] <- true
  else
    delete res[value]
  saveValue(id, res)
}

let nameLocCache = {}
let function getLocName(name) {
  if (name not in nameLocCache)
    nameLocCache[name] <- utf8ToLower(loc(getUnitPresentation(name).locId))
  return nameLocCache[name]
}

let idLowercaseCache = {}
let function getIdLowercase(name) {
  if (name not in idLowercaseCache)
    idLowercaseCache[name] <- name.tolower()
  return idLowercaseCache[name]
}

let nameId = "name"
let nameValue = mkValue(nameId, "")
let optName = {
  id = nameId
  ctrlType = OCT_TEXTINPUT
  locId = "options/unitName"
  value = nameValue
  setValue = mkSetValue(nameId)
  isFit = function(unit, value) {
    if (value == "")
      return true
    let lower = utf8ToLower(value)
    if (getLocName(unit.name).contains(lower) || getIdLowercase(unit.name) == lower)
      return true
    foreach (pu in unit.platoonUnits)
      if (getLocName(pu.name).contains(lower) || getIdLowercase(pu.name) == lower)
        return true
    return false
  }
}

let function mkOptMultiselect(id, override = {}) {
  let { getUnitValue = @(unit) unit?[id] } = override
  let allValues = override?.allValues
    ?? Computed(@() allUnitsCfg.value
      .reduce(function(res, unit) {
        res[getUnitValue(unit)] <- true
        return res
      }, {})
      .keys()
      .sort())
  let value = mkValue(id)
  return {
    ctrlType = OCT_MULTISELECT
    locId = $"options/{id}"
    value
    allValues
    setValue = mkSetValue(id)
    toggleValue = mkListToggleValue(id, allValues)
    getUnitValue
    isFit = @(unit, v) v == null || getUnitValue(unit) in v
  }.__update(override)
}


let optCountry = mkOptMultiselect("country", { valToString = loc })
let optUnitClass = mkOptMultiselect("unitClass", {
  function getUnitValue(unit) {
    let { unitClass = "" } = unit
    let text = loc($"mainmenu/type_{unitClass}")
    return $"{unitClassFontIcons?[unit?.unitClass] ?? "?"} {text}"
  }
})
let optMRank = mkOptMultiselect("mRank", { valToString = @(v) getRomanNumeral(v) })


let allStatuses = Computed(@() canBuyUnitsStatus.value
  .reduce(function(res, status) {
    res[status] <- true
    return res
  }, {})
  .keys()
  .sort())
let optStatus = mkOptMultiselect("unitStatus", {
  allValues = allStatuses
  getUnitValue = @(unit) canBuyUnitsStatus.value?[unit.name] ?? US_UNKNOWN
  valToString = @(st) loc(statusLoc?[st] ?? "???")
})

return {
  curFilters

  optName
  optCountry
  optUnitClass
  optMRank
  optStatus
}