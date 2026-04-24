from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { isDataBlock, eachParam, blk2SquirrelObjNoArrays } = require("%sqstd/datablock.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campConfigs, isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { campUnitsCfg, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { filters, filterGenId } = require("%rGui/unit/unitsFilterPkg.nut")
let { needToShowHiddenUnitsDebug } = require("%rGui/unit/debugUnits.nut")
let unreleasedUnits = require("%appGlobals/pServer/unreleasedUnits.nut")
let { unitsBlockedByBattleMode, blockedCountries } = require("%rGui/unit/unitAccess.nut")
let { subscribeResetProfile } = require("%rGui/account/resetProfileDetector.nut")


let SEEN_RESEARCHED_UNITS = "seenResearchedUnits"
let SEEN_VERSION_KEY = "seenResearchedUnitsVersion"
let ACTUAL_VERSION = 3

let countryPriority = {
  country_usa = 10
  country_germany = 9
  country_ussr = 8
}

let nodes = Computed(@() campConfigs.get()?.unitTreeNodes ?? {})
let needDebugNodes = mkWatched(persist, "needDebugNodes", false)

let visibleNodes = Computed(@()
  needToShowHiddenUnitsDebug.get() ? nodes.get()
    : nodes.get().filter(@(v) (!campUnitsCfg.get()?[v.name].isHidden && v.name not in unreleasedUnits.get())
      || v.name in campMyUnits.get()))

let selectedCountry = mkWatched(persist, "selectedCountry", null)
let shownUnitsOffersForPurchase = mkWatched(persist, "shownUnitsOffersForPurchase", {})
let seenResearchedUnits = mkWatched(persist, SEEN_RESEARCHED_UNITS, {})
let unitInfoToScroll = Watched(null)
let unitToScroll = Computed(@() unitInfoToScroll.get()?.name)

let unitsResearchStatus = Computed(function(prev) {
  let list = {}
  if (!isCampaignWithUnitsResearch.get())
    return list

  local hasChanges = false
  let { unitResearchExp = {} } = campConfigs.get()
  let { unitsResearch = {} } = servProfile.get()
  foreach (unitName, reqExp in unitResearchExp) {
    if (unitName in campMyUnits.get() || unitName not in campUnitsCfg.get())
      continue
    if (!needToShowHiddenUnitsDebug.get() && unitName in unreleasedUnits.get())
      continue
    let { reqUnits = [] , country = "" } = nodes.get()?[unitName]
    let { exp = 0, isCurrent = false, isResearched = false, canBuy = false, canResearch = false,
      hasAccessLock = true
    } = unitsResearch?[unitName]
    let res = {
      name = unitName
      exp
      reqExp
      reqUnits
      isCurrent
      isResearched
      canBuy
      canResearch
      hasAccessLock
      country
    }
    let value = prevIfEqual(prev?[unitName], res)
    list[unitName] <- value
    hasChanges = hasChanges || value != prev?[unitName]
  }

  return hasChanges || type(prev) != "table" || prev.len() != list.len() ? list : prev
})

let currentResearch = Computed(@() unitsResearchStatus.get().findvalue(@(r) r.isCurrent))
let researchCountry = Computed(@() currentResearch.get()?.country)

let isAllAvailableUnitsResearched = Computed(@()
   null == unitsResearchStatus.get().findvalue(@(r) (r.canResearch || r.canBuy)
     && ((r?.hasAccessLock ?? true) && r.name not in unitsBlockedByBattleMode.get())))

let mkCountries = @(nodeList) Computed(function(prev) {
  let resTbl = {}
  foreach (node in nodeList.get()) {
    if (node.name in unitsBlockedByBattleMode.get()
      && node.name not in campMyUnits.get()
      && currentResearch.get() == null
      && !isAllAvailableUnitsResearched.get())
      continue
    resTbl[node.country] <- true
  }
  let res = resTbl.keys()
    .sort(@(a, b) (countryPriority?[b] ?? -1) <=> (countryPriority?[a] ?? -1)
      || a <=> b)
  return prevIfEqual(prev, res)
})

let markUnitOfferShown = @(unitName) shownUnitsOffersForPurchase.mutate(@(v) v[unitName] <- true)

function mkFilteredNodes(nodeList) {
  let res = Computed(@() filterGenId.get() == 0 ? nodeList.get()
    : nodeList.get().filter(function(node) {
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
  foreach (f in filters) {
    let { allValues = null, valueWatch = null } = f
    if (allValues != null)
      res._noComputeErrorFor(allValues) 
    if (valueWatch != null)
      res._noComputeErrorFor(valueWatch) 
  }
  return res
}

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

function getArraySubArray(mainArr, idx) {
  for (local i = mainArr.len(); i <= idx; i++)
    mainArr.append([])
  return mainArr[idx]
}

function remapNodesPositions(nodeList) {
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
  return {
    xMax = xRemap?[xRemap.len() - 1] ?? 0
    yMax = yRemap?[yRemap.len() - 1] ?? 0
    nodes = nodeList.map(@(n) n.__merge({ x = xRemap[n.x], y = yRemap[n.y] }))
  }
}

function remapNodesPositionsShiftX(nodeList, serverConfigsV) {
  let { allUnits = {} } = serverConfigsV
  let nodesMap = [] 
  let rankXRanges = {}
  let yHas = []
  foreach (node in nodeList) {
    let { y, x, name, reqUnits } = node
    if (yHas.len() <= y)
      yHas.resize(y + 1, 0)
    yHas[y] = 1
    let { mRank = 1 } = allUnits?[name]
    let row = getArraySubArray(getArraySubArray(nodesMap, mRank - 1), y)
    if (row.len() == 0 && reqUnits.len() > 0) {
      local hasPrev = false
      local hasPrevSameY = false
      foreach (u in reqUnits)
        if ((allUnits?[u].mRank ?? 1) == mRank && (nodeList?[u].x ?? 1) < x) {
          hasPrev = true
          hasPrevSameY = hasPrevSameY || (nodeList?[u].y ?? 1) == y
        }
      if (hasPrev && !hasPrevSameY)
        row.append({ name = "", x = x - 1, y }) 
    }
    row.append(node)

    let range = getSubArray(rankXRanges, mRank)
    if (range.len() == 0)
      range.resize(2, x)
    else {
      range[0] = min(range[0], x)
      range[1] = max(range[1], x)
    }
  }

  let offsetsX = []
  foreach (r, rankRows in nodesMap) {
    if (offsetsX.len() <= r)
      offsetsX.resize(r + 1, 0)
    foreach (list in rankRows)
      offsetsX[r] = max(offsetsX[r], list.len())
  }
  for (local i = 0; i < offsetsX.len(); i++)
    offsetsX[i] += (offsetsX?[i - 1] ?? 0)

  let yRemap = sumRemap(yHas)
  let resNodes = {}
  foreach (r, rankRows in nodesMap)
    foreach (list in rankRows) {
      let rankX = (offsetsX?[r - 1] ?? 0) + 1 
      let rankXNext = max((offsetsX?[r] ?? 0) + 1, rankX + list.len())
      let range = getSubArray(rankXRanges, r + 1) 
      list.sort(@(a, b) a.x <=> b.x)
      foreach (i, node in list) {
        let { name, y, x } = node
        if (name == "")
          continue
        local nextX = rankX + i
        if (range.len() != 0)
          nextX = clamp(rankX + x - range[0], nextX, rankXNext - list.len() + i)
        resNodes[name] <- node.__merge({ x = nextX, y = yRemap[y] })
      }
    }

  return {
    xMax = offsetsX?[offsetsX.len() - 1] ?? 0
    yMax = yRemap?[yRemap.len() - 1] ?? 0
    nodes = resNodes
  }
}

let mkCountryNodesCfg = @(allNodes, curCountry) Computed(function(prev) {
  let nodeList = allNodes.get().filter(@(n) n.country == curCountry.get())
  let res = !needDebugNodes.get() || curCountry.get() == "legacy"
    ? remapNodesPositionsShiftX(nodeList, campConfigs.get())
    : remapNodesPositions(nodeList)
  return prevIfEqual(prev, res)
})

let allBlueprints = Computed(@() campConfigs.get()?.allBlueprints ?? {})
let blueprintCounts = Computed(@() servProfile.get()?.blueprints ?? {})

let availableBlueprints = Computed(@() allBlueprints.get()
  .filter(@(_, unitName) unitName not in campMyUnits.get() || unitName in campUnitsCfg.get()))

let blueprintUnitsStatus = Computed(function(prev) {
  let list = {}
  if (!isCampaignWithUnitsResearch.get())
    return list

  local hasChanges = false
  foreach (unitName, data in availableBlueprints.get()) {
    let { targetCount = 1 } = data
    let curCount = blueprintCounts.get()?[unitName] ?? 0
    let country = nodes.get()?[unitName] ?? ""
    let res = {
      name = unitName
      exp = curCount
      reqExp = targetCount
      isResearched = curCount >= targetCount
      canBuy = curCount >= targetCount
      country
    }
    let value = prevIfEqual(prev?[unitName], res)
    list[unitName] <- value
    hasChanges = hasChanges || value != prev?[unitName]
  }

  return hasChanges || type(prev) != "table" || prev.len() != list.len() ? list : prev
})

let unseenResearchedUnits = Computed(function() {
  let res = {}
  if (!isCampaignWithUnitsResearch.get())
    return res

  let { unitTreeNodes = {}, unitResearchExp = {} } = campConfigs.get()
  let { unitsResearch = {} } = servProfile.get()
  let blueprints = availableBlueprints.get()
  let bCounts = blueprintCounts.get()
  let seenUnits = seenResearchedUnits.get()

  foreach(unitName, node in unitTreeNodes) {
    let unit = campUnitsCfg.get()?[unitName]
    if (!unit || unit.isHidden || getTagsUnitName(unitName) in seenUnits)
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

function getResearchableCountries(nodeList, uResearchStatus, countriesToBlock) {
  let resTbl = {}
  foreach (node in nodeList) {
    let { canResearch = false, hasAccessLock = true } = uResearchStatus?[node.name]
    if (canResearch && (!hasAccessLock || node.country not in countriesToBlock))
      resTbl[node.country] <- true
  }
  return resTbl.keys()
    .sort(@(a, b) (countryPriority?[b] ?? -1) <=> (countryPriority?[a] ?? -1)
      || a <=> b)
}

let mkResearchableCountries = @(nodeList) Computed(function(prev) {
  let res = getResearchableCountries(nodeList.get(), unitsResearchStatus.get(), blockedCountries.get())
  return prevIfEqual(prev, res)
})

unitToScroll.subscribe(function(v) {
  let { country = null } = nodes.get()?[v]
  if (country != null)
    selectedCountry.set(country)
})

function setResearchedUnitsSeen(units) {
  let unseen = unseenResearchedUnits.get()
  let list = units.filter(@(_, u) null != unseen.findvalue(@(c) u in c))
  if (list.len() == 0)
    return

  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_RESEARCHED_UNITS)
  seenResearchedUnits.mutate(function(v) {
    foreach (u, _ in units) {
      let tagName = getTagsUnitName(u)
      v[tagName] <- true
      sBlk[tagName] = true
    }
  })
  eventbus_send("saveProfile", {})
}

function applyCompatibility() {
  let sBlk = get_local_custom_settings_blk()
  if ((sBlk?[SEEN_VERSION_KEY] ?? 0) == ACTUAL_VERSION)
    return

  sBlk[SEEN_VERSION_KEY] = ACTUAL_VERSION
  let toRemove = {}
  let toAdd = {}
  let blk = sBlk.addBlock(SEEN_RESEARCHED_UNITS)
  eachParam(blk, function(v, name) {
    if (getTagsUnitName(name) != name) {
      toRemove[name] <- true
      if (v)
        toAdd[getTagsUnitName(name)] <- true
    }
  })
  foreach (u, _ in toRemove)
    blk.removeParam(u)
  foreach (u, _ in toAdd)
    blk[u] <- true
}

function loadSeenResearchedUnits() {
  if (!isLoggedIn.get())
    return seenResearchedUnits.set({})
  applyCompatibility()
  let seenBlk = get_local_custom_settings_blk()?[SEEN_RESEARCHED_UNITS]
  seenResearchedUnits.set(isDataBlock(seenBlk) ? blk2SquirrelObjNoArrays(seenBlk) : {})
}

if (seenResearchedUnits.get().len() == 0)
  loadSeenResearchedUnits()

isLoggedIn.subscribe(@(_) loadSeenResearchedUnits())

function resetSeenResearchedUnit() {
  seenResearchedUnits.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_RESEARCHED_UNITS)
  eventbus_send("saveProfile", {})
}

register_command(@() resetSeenResearchedUnit(), "debug.reset_seen_researched_units")

register_command(function() {
  needDebugNodes.set(!needDebugNodes.get())
  console_print(needDebugNodes.get() ? "Show original positions" : "Show positions with offset") 
}, "debug.tree_original_positions")

subscribeResetProfile(function() {
  shownUnitsOffersForPurchase.set({})
  resetSeenResearchedUnit()
})

return {
  visibleNodes
  selectedCountry
  unitToScroll
  unitInfoToScroll
  setUnitToScroll = @(name, isAnimated = false) unitInfoToScroll.set({ name, isAnimated })
  mkCountries
  mkFilteredNodes
  mkCountryNodesCfg
  unitsResearchStatus
  currentResearch
  researchCountry
  blueprintUnitsStatus
  unseenResearchedUnits
  setResearchedUnitsSeen
  getResearchableCountries
  mkResearchableCountries

  shownUnitsOffersForPurchase
  markUnitOfferShown

  countryPriority
}