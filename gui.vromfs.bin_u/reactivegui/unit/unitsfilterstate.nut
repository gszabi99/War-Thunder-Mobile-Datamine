from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { campUnitsCfg, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { sortCountries } = require("%appGlobals/config/countryPresentation.nut")
let { unitClassFontIcons } = require("%appGlobals/unitPresentation.nut")
let { canBuyUnitsStatus, US_UNKNOWN, US_OWN, US_NOT_FOR_SALE, US_CAN_BUY, US_NOT_RESEARCHED,
  US_NEED_BLUEPRINTS, US_CAN_RESEARCH, UUP_NOT_UPGRADEABLE, UUP_UPGRADEABLE, UUP_UPGRADED,
  getUnitCategory, UC_RESEARCHABLE, UC_BLUEPRINT, UC_COLLECTIBLE, UC_PREMIUM, UC_SEASON_PREMIUM, UC_OTHER
} = require("%appGlobals/unitsState.nut")
let { OCT_TEXTINPUT, OCT_MULTISELECT, OCT_MULTISELECT_MASK } = require("%rGui/options/optCtrlType.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { mkFlagImageWithoutGrad, mkFlagFrame } = require("%rGui/unit/components/unitPlateComp.nut")
let { isUnitNameMatchSearchStr } = require("%rGui/unit/unitNameSearch.nut")


let curFiltersById = mkWatched(persist, "curFiltersById", {})

let statusLoc = {
  [US_OWN] = "options/unitOwn",
  [US_CAN_BUY] = "options/unitCanBuy",
  [US_NOT_FOR_SALE] = "options/unitCurrentlyAvailable", 
  [US_NOT_RESEARCHED] = "options/unitNotResearched",
  [US_NEED_BLUEPRINTS] = "options/unitNeedBlueprints",
  [US_CAN_RESEARCH] = "options/unitCanResearch",
}

let categoryLoc = {
  [UC_RESEARCHABLE] = "stats/research",
  [UC_BLUEPRINT] = "stats/blueprint",
  [UC_COLLECTIBLE] = "stats/rare",
  [UC_PREMIUM] = "stats/premium",
  [UC_SEASON_PREMIUM] = "stats/seasonPremium",
  [UC_OTHER] = "stats/other",
}

let upgradeLoc = {
  [UUP_NOT_UPGRADEABLE] = "options/notUpgradeable",
  [UUP_UPGRADEABLE] = "options/canUpgrade",
  [UUP_UPGRADED] = "options/upgraded",
}

let mkValue = @(id, curFilters, defValue = null) Computed(@() curFilters.get()?[id] ?? defValue)
let mkSetValue = @(id, setFilterValue) @(value) setFilterValue(id, value)

let textColor = 0xFFFFFFFF
let inactiveTextColor = 0xFFD96363

function fillFilters(filters) {
  foreach (f in filters ?? []) {
    if (f.ctrlType == OCT_MULTISELECT)
      f.setValue({})
    else if (f.ctrlType == OCT_MULTISELECT_MASK)
      f.setValue(0)
  }
}

let mkListToggleValue = @(id, curFilters, setFilterValue, allValuesW) function toggleValue(value, isChecked) {
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
  setFilterValue(id, res)
}

let mkListToggleAllValues = @(id, setFilterValue, allValuesW) function toggleAllValues(needMakeAllDisabled) {
  if (needMakeAllDisabled)
    setFilterValue(id, {})
  else {
    local newActiveAll = {}
    allValuesW.get().each(@(v) newActiveAll[v] <- true)
    setFilterValue(id, newActiveAll)
  }
}

let mkListToggleValueMask = @(id, curFilters, setFilterValue, allBits) function toggleValue(value, isChecked) {
  let res = curFilters.get()?[id] ?? allBits.get()
  if (((value & res) != 0x0) == isChecked)
    return
  setFilterValue(id, isChecked ? (res | value) : (res & ~value))
}

function optName(_, curFilters, setFilterValue) {
  let nameId = "name"
  let nameValue = mkValue(nameId, curFilters, "")
  return {
    id = nameId
    ctrlType = OCT_TEXTINPUT
    locId = "options/unitName"
    value = nameValue
    setValue = mkSetValue(nameId, setFilterValue)
    isFit = @(unit, value) value == "" ? true : isUnitNameMatchSearchStr(unit, value)
  }
}

let mkOptMultiselectCtor = @(id, override = {})
  function(units, curFilters, setFilterValue) {
    let { getUnitValue = @(unit) unit?[id], sortFunc = @(a,b) a <=> b, useAllToggle = false,
      mkAllValues = null
    } = override
    let allValues = mkAllValues?(units)
      ?? Computed(@() units.get()
        .reduce(function(res, unit) {
          res[getUnitValue(unit)] <- true
          return res
        }, {})
        .keys()
        .sort(sortFunc))
    let value = mkValue(id, curFilters)
    return {
      ctrlType = OCT_MULTISELECT
      locId = $"options/{id}"
      value
      allValues
      setValue = mkSetValue(id, setFilterValue)
      toggleValue = mkListToggleValue(id, curFilters, setFilterValue, allValues)
      toggleAllValues = useAllToggle ? mkListToggleAllValues(id, setFilterValue, allValues) : null
      getUnitValue
      isFit = @(unit, v) v == null || getUnitValue(unit) in v
    }.__update(override)
  }

let optCountry = mkOptMultiselectCtor("country", {
  customValue = @(v, hasValues) hasValues
    ? mkFlagImageWithoutGrad(v, hdpxi(90))
    : mkFlagFrame(mkFlagImageWithoutGrad(v, hdpxi(90)), { borderColor = inactiveTextColor })
  sortFunc = sortCountries
  useAllToggle = true
})
let optMRank = mkOptMultiselectCtor("mRank", {
  inBoxValue = @(v, hasValues) mkGradRank(v, hasValues ? {} : { fontTex = null, fontTexSv = null, color = inactiveTextColor })
  useAllToggle = true
})
let optUnitClass = mkOptMultiselectCtor("unitClass", {
  inBoxValue = @(v, hasValues) {
    rendObj = ROBJ_TEXT
    color = hasValues ? textColor : inactiveTextColor
    text = unitClassFontIcons?[v]
  }.__update(fontBig)
  useAllToggle = true
  tooltipCtorId = "unitClass"
})

let optStatus = mkOptMultiselectCtor("unitStatus", {
  mkAllValues = @(units) Computed(function() {
    let status = canBuyUnitsStatus.get()
    return units.get()
      .reduce(function(res, _, name) {
        if (name in status)
          res[status[name]] <- true
        return res
      }, {})
      .keys()
      .sort()
  })
  getUnitValue = @(unit) canBuyUnitsStatus.get()?[unit.name] ?? US_UNKNOWN
  valueWatch = canBuyUnitsStatus
  valToString = @(st) loc(statusLoc?[st] ?? "???")
  locId = null
})

function optType(units, curFilters, setFilterValue) {
  let unitCategories = Computed(function() {
    let { unitResearchExp = {}, allBlueprints = {} } = serverConfigs.get()
    return units.get().map(@(u) getUnitCategory(u, unitResearchExp, allBlueprints))
  })

  let allCategoriesMask = Computed(function() {
    let allCats = unitCategories.get()
    local mask = 0
    foreach (uName, _ in units.get())
      mask = mask | (allCats?[uName] ?? UC_OTHER)
    return mask
  })

  let optTypeId = "unitGroup"
  return {
    id = optTypeId
    locId = null
    ctrlType = OCT_MULTISELECT_MASK
    valToString = @(st) loc(categoryLoc?[st] ?? "???")
    value = mkValue(optTypeId, curFilters)
    setValue = mkSetValue(optTypeId, setFilterValue)
    allValues = allCategoriesMask
    toggleValue = mkListToggleValueMask(optTypeId, curFilters, setFilterValue, allCategoriesMask)
    getUnitValue = @(unit) unitCategories.get()?[unit.name] ?? UC_OTHER
    valueWatch = unitCategories
    isFit = @(unit, v) ((unitCategories.get()?[unit.name] ?? UC_OTHER) & v) != 0x0
  }
}

function optUpgrade(units, curFilters, setFilterValue) {
  let unitUpgrades = Computed(function() {
    let my = campMyUnits.get()
    return units.get().map(@(u, name) !u.isUpgradeable ? UUP_NOT_UPGRADEABLE
      : my?[name].isUpgraded ? UUP_UPGRADED
      : UUP_UPGRADEABLE)
  })

  let allUpgradesMask = Computed(function() {
    let all = unitUpgrades.get()
    let my = campMyUnits.get()
    local mask = 0
    foreach (uName, u in units.get())
      if (!u.isHidden || uName in my)
        mask = mask | (all?[uName] ?? UUP_NOT_UPGRADEABLE)
    return mask
  })

  let optUpgradeId = "unitUpgrade"
  return {
    id = optUpgradeId
    locId = null
    ctrlType = OCT_MULTISELECT_MASK
    valToString = @(st) loc(upgradeLoc?[st] ?? "???")
    value = mkValue(optUpgradeId, curFilters)
    setValue = mkSetValue(optUpgradeId, setFilterValue)
    allValues = allUpgradesMask
    toggleValue = mkListToggleValueMask(optUpgradeId, curFilters, setFilterValue, allUpgradesMask)
    getUnitValue = @(unit) unitUpgrades.get()?[unit.name] ?? UUP_NOT_UPGRADEABLE
    valueWatch = unitUpgrades
    isFit = @(unit, v) ((unitUpgrades.get()?[unit.name] ?? UUP_NOT_UPGRADEABLE) & v) != 0x0
  }
}

let mkAllFilters = @(units, curFilters, setFilterValue)
  [optName, optStatus, optUnitClass, optMRank, optCountry, optType, optUpgrade]
    .map(@(ctor) ctor(units, curFilters, setFilterValue))

function mkFilteredNodes(filters, nodes, filterGenId) {
  let res = Computed(@() filterGenId.get() == 0 ? nodes.get()
    : nodes.get().filter(function(node) {
        let unit = campUnitsCfg.get()?[node.name]
        if (!unit)
          return false
        foreach (f in filters) {
          let value = f.value.get()
          if (value != null && !f.isFit(unit, value))
            return false
        }
        return true
      }))
  return res
}

function resetFilters(setId) {
  if (setId in curFiltersById.get())
    curFiltersById.mutate(@(v) v.$rawdelete(setId))
}

function setFilterValueImpl(setId, filterId, value) {
  if (curFiltersById.get()?[setId][filterId] != value)
    curFiltersById.mutate(function(v) {
      let setData = (clone v?[setId]) ?? {}
      setData[filterId] <- value
      v[setId] <- setData
    })
}

function mkFilters(setId, allNodes) {
  let allUnits = Computed(function() {
    let res = {}
    let campUnits = campUnitsCfg.get()
    foreach (name, _ in allNodes.get())
      if (name in campUnits)
        res[name] <- campUnits[name]
    return res
  })
  let curFilters = Computed(@() curFiltersById.get()?[setId] ?? {})
  let filters = mkAllFilters(allUnits, curFilters, @(id, value) setFilterValueImpl(setId, id, value))
  let filterGenId = Watched(curFilters.get().len())
  let activeFilters = Watched(0)

  function countActiveFilters() {
    filterGenId.set(filterGenId.get() + 1)
    return activeFilters.set(filters.reduce(function(res, f) {
      let value = f.value.get()
      if (value != null && value != ""
          && (type(value) != "table" || value.len() < f.allValues.get().len()))
        res++
      return res
    }, 0))
  }
  countActiveFilters()
  let countActiveFiltersSubs = @(_) deferOnce(countActiveFilters)
  foreach (f in filters) {
    f.value.subscribe(countActiveFiltersSubs)
    f?.allValues.subscribe(countActiveFiltersSubs)
    f?.valueWatch.subscribe(countActiveFiltersSubs)
  }

  return { filters, activeFilters, allUnits,
    filteredNodes = mkFilteredNodes(filters, allNodes, filterGenId)
  }
}

return {
  mkFilters
  fillFilters
  resetFilters
}