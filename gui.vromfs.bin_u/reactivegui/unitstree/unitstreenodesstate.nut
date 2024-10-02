from "%globalsDarg/darg_library.nut" import *
let { isEqual } = require("%sqstd/underscore.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { allUnitsCfg, myUnits } = require("%appGlobals/pServer/profile.nut")
let { filters, filterCount } = require("%rGui/unit/unitsFilterPkg.nut")
let { needToShowHiddenUnitsDebug } = require("%rGui/unit/debugUnits.nut")

let countryPriority = {
  country_usa = 10
  country_germany = 9
  country_ussr = 8
}

let nodes = Computed(@() serverConfigs.get()?.unitTreeNodes[curCampaign.get()] ?? {})
let selectedCountry = mkWatched(persist, "selectedCountry", null)
let unitToScroll = Watched(null)

let mkCountries = @(nodeList) Computed(function(prev) {
  let resTbl = {}
  foreach (node in nodeList.get())
    resTbl[node.country] <- true
  let res = resTbl.keys()
    .sort(@(a, b) (countryPriority?[b] ?? -1) <=> (countryPriority?[a] ?? -1)
      || a <=> b)
  return isEqual(res, prev) ? prev : res
})

let mkVisibleNodes = @() Computed(@()
  needToShowHiddenUnitsDebug.get() ? nodes.get()
    : nodes.get().filter(@(v) !allUnitsCfg.get()?[v.name].isHidden || v.name in myUnits.get()))

let mkFilteredNodes = @(nodeList) Computed(@()
  filterCount.get() == 0 ? nodeList.get()
    : nodeList.get()
      .filter(function(node) {
        foreach (f in filters) {
          let value = f.value.get()
          if (value != null && !f.isFit(allUnitsCfg.get()?[node.name], value))
            return false
        }
        return true
      }))

function sumRemap(has) {
  let res = []
  local count = 0
  foreach (v in has) {
    if (v > 0)
      count++
    res.append(count)
  }
  return res
}

let mkCountryNodesCfg = @(allNodes, curCountry) Computed(function(prev) {
  let nodeList = allNodes.get().filter(@(n) n.country == curCountry.get())
  let xHas = []
  let yHas = []
  foreach (node in nodeList) {
    let { x, y } = node
    if (xHas.len() <= x)
      xHas.resize(x + 1, 0)
    xHas[x] = 1
    if (yHas.len() <= y)
      yHas.resize(y + 1, 0)
    yHas[y] = 1
  }
  let xRemap = sumRemap(xHas)
  let yRemap = sumRemap(yHas)
  let res = {
    xMax = xRemap?[xRemap.len() - 1] ?? 0
    yMax = yRemap?[yRemap.len() - 1] ?? 0
    nodes = nodeList.map(@(n) n.__merge({ x = xRemap[n.x], y = yRemap[n.y] }))
  }
  return isEqual(res, prev) ? prev : res
})

let allBlueprints = Computed(@() serverConfigs.get()?.allBlueprints ?? {})
let blueprintCounts = Computed(@() servProfile.get()?.blueprints ?? {})

let availableBlueprints = Computed(@() allBlueprints.get()
  .filter(@(_, unitName) unitName not in myUnits.get() || unitName in allUnitsCfg.get()))

let blueprintUnitsStatus = Computed(function(prev) {
  let list = {}
  foreach (unitName, data in availableBlueprints.get()) {
    let { targetCount = 1 } = data
    let curCount = blueprintCounts.get()?[unitName] ?? 0

    list[unitName] <- {
      name = unitName
      exp = curCount
      reqExp = targetCount
      isResearched = curCount >= targetCount
      canBuy = curCount >= targetCount
    }
  }

  if (type(prev) != "table" || prev.len() != list.len())
    return list

  let res = {}
  local hasChanges = false
  foreach (unitName, r in list)
    if (isEqual(r, prev?[unitName]))
      res[unitName] <- prev[unitName]
    else {
      res[unitName] <- r
      hasChanges = true
    }

  return hasChanges ? res : prev
})

let unitsResearchStatus = Computed(function(prev) {
  let list = {}
  let { unitResearchExp = {} } = serverConfigs.get()
  let { unitsResearch = {} } = servProfile.get()
  foreach (unitName, reqExp in unitResearchExp) {
    if (unitName in myUnits.get() || unitName not in allUnitsCfg.get())
      continue
    let { reqUnits = [] , country = "" } = nodes.get()?[unitName]
    let { exp = 0, isCurrent = false, isResearched = false, canBuy = false, canResearch = false } = unitsResearch?[unitName]
    list[unitName] <- {
      name = unitName
      exp
      reqExp
      reqUnits
      isCurrent
      isResearched
      canBuy
      canResearch
      country
    }
  }

  if (type(prev) != "table" || prev.len() != list.len())
    return list

  let res = {}
  local hasChanges = false
  foreach (unitName, r in list)
    if (isEqual(r, prev?[unitName]))
      res[unitName] <- prev[unitName]
    else {
      res[unitName] <- r
      hasChanges = true
    }

  return hasChanges ? res : prev
})

let currentResearch = Computed(@() unitsResearchStatus.get().findvalue(@(r) r.isCurrent))

let researchCountry = Computed(@() currentResearch.get()?.country)

unitToScroll.subscribe(function(v) {
  let { country = null } = nodes.get()?[v]
  if (country != null)
    selectedCountry.set(country)
})

return {
  nodes
  selectedCountry
  unitToScroll
  mkCountries
  mkVisibleNodes
  mkFilteredNodes
  mkCountryNodesCfg
  unitsResearchStatus
  currentResearch
  researchCountry
  blueprintUnitsStatus
}