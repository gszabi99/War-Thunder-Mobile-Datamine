from "%globalsDarg/darg_library.nut" import *
let { OCT_TEXTINPUT, OCT_MULTISELECT } = require("%rGui/options/optCtrlType.nut")
let { unitClassFontIcons } = require("%appGlobals/unitPresentation.nut")
let { allUnitsCfg, myUnits } = require("%appGlobals/pServer/profile.nut")
let { canBuyUnitsStatus, US_UNKNOWN, US_OWN, US_NOT_FOR_SALE, US_CAN_BUY, US_TOO_LOW_LEVEL, US_NOT_RESEARCHED,
  US_NEED_BLUEPRINTS, US_CAN_RESEARCH
} = require("%appGlobals/unitsState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { mkFlagImage } = require("%rGui/unitsTree/unitsTreeComps.nut")
let { isUnitNameMatchSearchStr } = require("%rGui/unit/unitNameSearch.nut")


let statusLoc = {
  [US_OWN] = "options/unitOwn",
  [US_CAN_BUY] = "options/unitCanBuy",
  [US_TOO_LOW_LEVEL] = "options/unitNeedLevel",
  [US_NOT_FOR_SALE] = "options/unitNotForSale",
  [US_NOT_RESEARCHED] = "options/unitNotResearched",
  [US_NEED_BLUEPRINTS] = "options/unitNeedBlueprints",
  [US_CAN_RESEARCH] = "options/unitCanResearch",
}

let curFilters = mkWatched(persist, "curFilters", {})
let mkValue = @(id, defValue = null) Computed(@() curFilters.value?[id] ?? defValue)
let saveValue = @(id, value) curFilters.mutate(@(f) f[id] <- value)
let mkSetValue = @(id) @(value) saveValue(id, value)
let clearFilters = @() curFilters.set({})

curCampaign.subscribe(@(_) clearFilters())

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
    res.$rawdelete(value)
  saveValue(id, res)
}

let nameId = "name"
let nameValue = mkValue(nameId, "")
let optName = {
  id = nameId
  ctrlType = OCT_TEXTINPUT
  locId = "options/unitName"
  value = nameValue
  setValue = mkSetValue(nameId)
  isFit = @(unit, value) value == "" ? true : isUnitNameMatchSearchStr(unit, value)
}

function mkOptMultiselect(id, override = {}) {
  let { getUnitValue = @(unit) unit?[id] } = override
  let allValues = override?.allValues
    ?? Computed(@() allUnitsCfg.value
      .filter(@(u) !u?.isHidden || u.name in myUnits.value)
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

let optCountry = mkOptMultiselect("country", { customValue = @(v) mkFlagImage(v, hdpxi(90)) })
let optMRank = mkOptMultiselect("mRank", { inBoxValue = @(v) mkGradRank(v) })
let optUnitClass = mkOptMultiselect("unitClass", { inBoxValue = @(v) {
  rendObj = ROBJ_TEXT
  text = unitClassFontIcons?[v]
}.__update(fontBig) })

let allStatuses = Computed(@() canBuyUnitsStatus.value
  .reduce(function(res, status, unitName) {
    if (!allUnitsCfg.get()?[unitName].isHidden)
      res[status] <- true
    return res
  }, {})
  .keys()
  .sort())
let optStatus = mkOptMultiselect("unitStatus", {
  allValues = allStatuses
  getUnitValue = @(unit) canBuyUnitsStatus.value?[unit.name] ?? US_UNKNOWN
  valToString = @(st) loc(statusLoc?[st] ?? "???")
  locId = null
})

return {
  curFilters
  clearFilters

  optName
  optCountry
  optMRank
  optStatus
  optUnitClass
}