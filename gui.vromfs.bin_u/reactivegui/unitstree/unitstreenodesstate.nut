from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")

let { isEqual } = require("%sqstd/underscore.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")

let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign, isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { campUnitsCfg, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { filters, filterGenId } = require("%rGui/unit/unitsFilterPkg.nut")
let { needToShowHiddenUnitsDebug } = require("%rGui/unit/debugUnits.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")

let SEEN_RESEARCHED_UNITS = "seenResearchedUnits"

let countryPriority = {
  country_usa = 10
  country_germany = 9
  country_ussr = 8
}

let nodes = Computed(@() serverConfigs.get()?.unitTreeNodes[curCampaign.get()] ?? {})
let selectedCountry = mkWatched(persist, "selectedCountry", null)
let seenResearchedUnits = mkWatched(persist, SEEN_RESEARCHED_UNITS, {})
let unitInfoToScroll = Watched(null)
let unitToScroll = Computed(@() unitInfoToScroll.get()?.name)

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
    : nodes.get().filter(@(v) (!campUnitsCfg.get()?[v.name].isHidden && v.name in releasedUnits.get())
      || v.name in campMyUnits.get()))

let mkFilteredNodes = @(nodeList) Computed(@()
  filterGenId.get() == 0 ? nodeList.get()
    : nodeList.get()
      .filter(function(node) {
        foreach (f in filters) {
          let value = f.value.get()
          if (value != null && !f.isFit(campUnitsCfg.get()?[node.name], value))
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

function computeChanges(prev, list) {
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
}

let allBlueprints = Computed(@() serverConfigs.get()?.allBlueprints ?? {})
let blueprintCounts = Computed(@() servProfile.get()?.blueprints ?? {})

let availableBlueprints = Computed(@() allBlueprints.get()
  .filter(@(_, unitName) unitName not in campMyUnits.get() || unitName in campUnitsCfg.get()))

let blueprintUnitsStatus = Computed(function(prev) {
  let list = {}
  if (!isCampaignWithUnitsResearch.get())
    return list
  foreach (unitName, data in availableBlueprints.get()) {
    let { targetCount = 1 } = data
    let curCount = blueprintCounts.get()?[unitName] ?? 0
    let country = nodes.get()?[unitName] ?? ""

    list[unitName] <- {
      name = unitName
      exp = curCount
      reqExp = targetCount
      isResearched = curCount >= targetCount
      canBuy = curCount >= targetCount
      country
    }
  }

  return computeChanges(prev, list)
})

let unitsResearchStatus = Computed(function(prev) {
  let list = {}
  if (!isCampaignWithUnitsResearch.get())
    return list
  let { unitResearchExp = {} } = serverConfigs.get()
  let { unitsResearch = {} } = servProfile.get()
  foreach (unitName, reqExp in unitResearchExp) {
    if (unitName in campMyUnits.get() || unitName not in campUnitsCfg.get())
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

  return computeChanges(prev, list)
})

let unseenResearchedUnits = Computed(function() {
  let res = {}
  if (!isCampaignWithUnitsResearch.get())
    return res

  let { unitTreeNodes, unitResearchExp = {} } = serverConfigs.get()
  let { unitsResearch = {} } = servProfile.get()
  let curCampaignUnits = unitTreeNodes[curCampaign.get()]
  let blueprints = availableBlueprints.get()
  let bCounts = blueprintCounts.get()
  let seenUnits = seenResearchedUnits.get()

  foreach(unitName, node in curCampaignUnits) {
    let unit = campUnitsCfg.get()?[unitName]
    if (!unit || unit.isHidden || unitName in seenUnits)
      continue

    let { country = "" } = node

    local isUnseenUnit = false

    if (unitName not in campMyUnits.get() && unitName in unitResearchExp) {
      let { isResearched = false, canBuy = false } = unitsResearch?[unitName]
      isUnseenUnit = isResearched && canBuy
    }
    else if (unitName not in campMyUnits.get() && unitName in blueprints) {
      let { targetCount } = blueprints[unitName]
      let curCount = bCounts?[unitName] ?? 0
      isUnseenUnit = curCount >= targetCount
    }
    else if (unit.isPremium)
      isUnseenUnit = unitName in campMyUnits.get()

    if(isUnseenUnit) {
      if(country not in res)
        res[country] <- {}
      res[country][unitName] <- true
    }
  }

  return res
})

let currentResearch = Computed(@() unitsResearchStatus.get().findvalue(@(r) r.isCurrent))

let researchCountry = Computed(@() currentResearch.get()?.country)

unitToScroll.subscribe(function(v) {
  let { country = null } = nodes.get()?[v]
  if (country != null)
    selectedCountry.set(country)
})

function setResearchedUnitsSeen(units) {
  if (!units || units.len() == 0)
    return

  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_RESEARCHED_UNITS)

  seenResearchedUnits.mutate(function(v) {
    foreach(unit, _ in units) {
      v[unit] <- true
      sBlk[unit] = true
    }
  })

  eventbus_send("saveProfile", {})
}

function loadSeenResearchedUnits() {
  if (!isSettingsAvailable.get())
    return seenResearchedUnits.set({})
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SEEN_RESEARCHED_UNITS]
  if (!isDataBlock(htBlk))
    return seenResearchedUnits.set({})

  let res = {}
  eachParam(htBlk, @(isSeen, id) res[id] <- isSeen)
  seenResearchedUnits.set(res)
}

if (seenResearchedUnits.get().len() == 0)
  loadSeenResearchedUnits()

isSettingsAvailable.subscribe(@(_) loadSeenResearchedUnits())

register_command(function() {
  seenResearchedUnits.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_RESEARCHED_UNITS)
  eventbus_send("saveProfile", {})
}, "debug.reset_seen_researched_units")

return {
  nodes
  selectedCountry
  unitToScroll
  unitInfoToScroll
  setUnitToScroll = @(name, isAnimated = false) unitInfoToScroll.set({ name, isAnimated })
  mkCountries
  mkVisibleNodes
  mkFilteredNodes
  mkCountryNodesCfg
  unitsResearchStatus
  currentResearch
  researchCountry
  blueprintUnitsStatus
  unseenResearchedUnits
  setResearchedUnitsSeen

  countryPriority
}