from "%globalsDarg/darg_library.nut" import *
let { OCT_TEXTINPUT, OCT_MULTISELECT, OCT_MULTISELECT_MASK } = require("%rGui/options/optCtrlType.nut")
let { unitClassFontIcons } = require("%appGlobals/unitPresentation.nut")
let { campUnitsCfg, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { sortCountries } = require("%appGlobals/config/countryPresentation.nut")
let { canBuyUnitsStatus, US_UNKNOWN, US_OWN, US_NOT_FOR_SALE, US_CAN_BUY, US_TOO_LOW_LEVEL, US_NOT_RESEARCHED,
  US_NEED_BLUEPRINTS, US_CAN_RESEARCH, UG_ALL, UG_COMMON, UG_UPGRADED, UG_PREMIUM, UG_COLLECTIBLE, getUnitGroupMask
} = require("%appGlobals/unitsState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { mkFlagImageWithoutGrad } = require("%rGui/unit/components/unitPlateComp.nut")
let { isUnitNameMatchSearchStr } = require("%rGui/unit/unitNameSearch.nut")
let unreleasedUnits = require("%appGlobals/pServer/unreleasedUnits.nut")


let statusLoc = {
  [US_OWN] = "options/unitOwn",
  [US_CAN_BUY] = "options/unitCanBuy",
  [US_TOO_LOW_LEVEL] = "options/unitNeedLevel",
  [US_NOT_FOR_SALE] = "options/unitNotForSale",
  [US_NOT_RESEARCHED] = "options/unitNotResearched",
  [US_NEED_BLUEPRINTS] = "options/unitNeedBlueprints",
  [US_CAN_RESEARCH] = "options/unitCanResearch",
}

let groupLoc = {
  [UG_COMMON] = "options/common",
  [UG_UPGRADED] = "options/upgraded",
  [UG_PREMIUM] = "options/premium",
  [UG_COLLECTIBLE] = "options/collectible",
}

let curFilters = mkWatched(persist, "curFilters", {})
let mkValue = @(id, defValue = null) Computed(@() curFilters.get()?[id] ?? defValue)
let saveValue = @(id, value) curFilters.mutate(@(f) f[id] <- value)
let mkSetValue = @(id) @(value) saveValue(id, value)
let clearFilters = @() curFilters.set({})

function fillFilters(filters) {
  foreach (f in filters ?? []) {
    if (f.ctrlType == OCT_MULTISELECT)
      f.setValue({})
    else if (f.ctrlType == OCT_MULTISELECT_MASK)
      f.setValue(0)
  }
}

curCampaign.subscribe(@(_) clearFilters())

let mkListToggleValue = @(id, allValuesW) function toggleValue(value, isChecked) {
  local res = curFilters.get()?[id]
  if (res == null) {
    res = {}
    allValuesW.get().each(@(v) res[v] <- true)
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

let mkListToggleAllValues = @(id, allValuesW) function toggleAllValues(needMakeAllDisabled) {
  if (needMakeAllDisabled)
    saveValue(id, {})
  else {
    local newActiveAll = {}
    allValuesW.get().each(@(v) newActiveAll[v] <- true)
    saveValue(id, newActiveAll)
  }
}

let mkListToggleValueMask = @(id, allBits) function toggleValue(value, isChecked) {
  let res = curFilters.get()?[id] ?? allBits.get()
  if (((value & res) != 0x0) == isChecked)
    return
  saveValue(id, isChecked ? (res | value) : (res & ~value))
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
  let { getUnitValue = @(unit) unit?[id], sortFunc = @(a,b) a <=> b, useAllToggle = false } = override
  let allValues = override?.allValues
    ?? Computed(@() campUnitsCfg.get()
      .filter(@(u) (!u?.isHidden && u.name not in unreleasedUnits.get()) || u.name in campMyUnits.get())
      .reduce(function(res, unit) {
        res[getUnitValue(unit)] <- true
        return res
      }, {})
      .keys()
      .sort(sortFunc))
  let value = mkValue(id)
  return {
    ctrlType = OCT_MULTISELECT
    locId = $"options/{id}"
    value
    allValues
    setValue = mkSetValue(id)
    toggleValue = mkListToggleValue(id, allValues)
    toggleAllValues = useAllToggle ? mkListToggleAllValues(id, allValues) : null
    getUnitValue
    isFit = @(unit, v) v == null || getUnitValue(unit) in v
  }.__update(override)
}

let optCountry = mkOptMultiselect("country", {
  customValue = @(v) mkFlagImageWithoutGrad(v, hdpxi(90))
  sortFunc = sortCountries
  useAllToggle = true
})
let optMRank = mkOptMultiselect("mRank", {
  inBoxValue = @(v) mkGradRank(v)
  useAllToggle = true
})
let optUnitClass = mkOptMultiselect("unitClass", {
  inBoxValue = @(v) {
    rendObj = ROBJ_TEXT
    text = unitClassFontIcons?[v]
  }.__update(fontBig)
  useAllToggle = true
  tooltipCtorId = "unitClass"
})

let allStatuses = Computed(@() canBuyUnitsStatus.get()
  .reduce(function(res, status, unitName) {
    if (!campUnitsCfg.get()?[unitName].isHidden)
      res[status] <- true
    return res
  }, {})
  .keys()
  .sort())
let optStatus = mkOptMultiselect("unitStatus", {
  allValues = allStatuses
  getUnitValue = @(unit) canBuyUnitsStatus.get()?[unit.name] ?? US_UNKNOWN
  valueWatch = canBuyUnitsStatus
  valToString = @(st) loc(statusLoc?[st] ?? "???")
  locId = null
})

let allTypesMask = Computed(function() {
  local mask = 0
  foreach (uName, u in campUnitsCfg.get()) {
    if (uName not in campMyUnits.get() && u?.isHidden)
      continue

    mask = mask | getUnitGroupMask(u)
    if (mask == UG_ALL)
      break
  }
  return mask
})

let optTypeId = "unitGroup"
let optType = {
  id = optTypeId
  locId = null
  ctrlType = OCT_MULTISELECT_MASK
  valToString = @(st) loc(groupLoc?[st] ?? "???")
  value = mkValue(optTypeId)
  setValue = mkSetValue(optTypeId)
  allValues = allTypesMask
  toggleValue = mkListToggleValueMask(optTypeId, allTypesMask)
  getUnitValue = getUnitGroupMask
  isFit = @(unit, v) (getUnitGroupMask(unit) & v) != 0x0
}

return {
  curFilters
  clearFilters
  fillFilters

  optName
  optCountry
  optMRank
  optStatus
  optUnitClass
  optType
}