from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
from "math" import ceil
from "%sqstd/datablock.nut" import isDataBlock, eachParam, blk2SquirrelObjNoArrays
from "%sqstd/underscore.nut" import prevIfEqual
import "%appGlobals/getTagsUnitName.nut" as getTagsUnitName
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/profile.nut" import campUnitsCfg, campMyUnits
import "%appGlobals/pServer/servProfile.nut" as servProfile
import "%appGlobals/pServer/unreleasedUnits.nut" as unreleasedUnits
from "%rGui/account/resetProfileDetector.nut" import subscribeResetProfile
from "%rGui/unit/debugUnits.nut" import needToShowHiddenUnitsDebug
from "%rGui/unit/unitAccess.nut" import unitsBlockedByBattleMode, blockedCountries
from "types" import Table


const SEEN_RESEARCHED_UNITS = "seenResearchedUnits"
const SEEN_VERSION_KEY = "seenResearchedUnitsVersion"
const ACTUAL_VERSION = 3

let countryPriority = {
  country_usa = 10
  country_germany = 9
  country_ussr = 8
}

let nodes = Computed(@() campConfigs.get()?.unitTreeNodes ?? {})
let needDebugNodes = mkWatched(persist, "needDebugNodes", false)
let needDebugLines = mkWatched(persist, "needDebugLines", false)

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

  return hasChanges || !(prev instanceof Table) || prev.len() != list.len() ? list : prev
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

function calcNodesOffsetsX(nodesMap) {
  let offsetsX = []
  foreach (r, rankRows in nodesMap) {
    if (offsetsX.len() <= r)
      offsetsX.resize(r + 1, 0)
    foreach (list in rankRows)
      offsetsX[r] = max(offsetsX[r], list.len())
  }
  for (local i = 0; i < offsetsX.len(); i++)
    offsetsX[i] += (offsetsX?[i - 1] ?? 0)
  return offsetsX
}

function compressHeaderUnits(nodesMap, yHas, lastHeaderY) {
  let width1 = [] 
  let width2 = [] 
  let headerNodes = []
  let isFilledHeaderRow = array(lastHeaderY + 1, 0)
  foreach (r, rankRows in nodesMap) {
    if (width1.len() <= r) {
      width1.resize(r + 1, 0)
      width2.resize(r + 1, 0)
      for (local i = headerNodes.len(); i <= r; i++)
        headerNodes.append([])
    }
    foreach (y, list in rankRows)
      if (y > lastHeaderY)
        width2[r] = max(width2[r], list.len())
      else if (list.len() > 0) {
        width1[r] = max(width1[r], list.len())
        headerNodes[r].extend(list)
        isFilledHeaderRow[y] = 1
      }
  }

  
  local headerRows = 1
  let maxHeaderRows = isFilledHeaderRow.reduce(@(res, v) res + v, 0)
  foreach (r, list in headerNodes) {
    if (list.len() == 0)
      continue
    let w = max(width1[r], width2[r])
    headerRows = clamp(ceil(list.len().tofloat() / w).tointeger(), headerRows, maxHeaderRows)
  }

  
  for (local y = 0; y <= lastHeaderY; y++)
    yHas[y] = 0
  foreach (rList in nodesMap)
    foreach (y, yList in rList)
      if (y <= lastHeaderY)
        yList.clear()
      else
        break

  
  foreach (r, list in headerNodes) {
    if (list.len() == 0)
      continue
    let w = max(width2[r], ceil(list.len().tofloat() / headerRows).tointeger())
    width1[r] = w
    list.sort(@(a, b) b.y <=> a.y || b.x <=> a.x) 
    foreach (i, n in list) {
      let row = i / w
      let idx = i % w
      let y = lastHeaderY - row
      n.y = y
      n.x = w - idx 
      yHas[y] = 1
      getArraySubArray(getArraySubArray(nodesMap, r), y).append(n)
    }
  }

  let totalRanks = width1.len()
  let offsetsX = []
  for (local i = 0; i < totalRanks; i++)
    offsetsX.append((offsetsX?[i - 1] ?? 0) + max(width1?[i] ?? 0, width2?[i] ?? 0))
  return offsetsX
}

function remapNodesPositionsShiftX(nodeList, serverConfigsV, shouldMoveHeaderY) {
  let { allUnits = {} } = serverConfigsV
  let nodesMap = [] 
  let rankXRanges = {}
  let yHas = []
  local premiumYMax = 0
  local headerYMax = shouldMoveHeaderY ? null : -1
  foreach (node in nodeList) {
    let { y, x, name, reqUnits } = node
    if (yHas.len() <= y)
      yHas.resize(y + 1, 0)
    yHas[y] = 1

    if (reqUnits.len() > 0)
      headerYMax = min(headerYMax ?? y, y - 1)
    if (allUnits?[name].isPremium)
      premiumYMax = max(premiumYMax, y)

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
    else if (row.len() > 0 && row.top().x > x && row[0].name == "")
      row.remove(0) 
    row.append(clone node)

    let range = getSubArray(rankXRanges, mRank)
    if (range.len() == 0)
      range.resize(2, x)
    else {
      range[0] = min(range[0], x)
      range[1] = max(range[1], x)
    }
  }

  let lastHeaderY = min(premiumYMax, headerYMax ?? -1)
  let offsetsX = lastHeaderY < 0 ? calcNodesOffsetsX(nodesMap)
    : compressHeaderUnits(nodesMap, yHas, lastHeaderY) 

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
        node.x = nextX
        node.y = yRemap[y]
        resNodes[name] <- node
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
  let isLegacy = curCountry.get() == "legacy"
  let res = !needDebugNodes.get() || isLegacy
    ? remapNodesPositionsShiftX(nodeList, campConfigs.get(), !isLegacy)
    : remapNodesPositions(nodeList)
  return prevIfEqual(prev, res)
})

let allBlueprints = Computed(@() campConfigs.get()?.allBlueprints ?? {})
let blueprintCounts = Computed(@() servProfile.get()?.blueprints ?? {})

let availableBlueprints = Computed(@() allBlueprints.get()
  .filter(@(_, unitName) unitName not in campMyUnits.get() || unitName in campUnitsCfg.get()))

let blueprintUnitsStatus = Computed(function(prev) {
  let list = {}
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

  return hasChanges || !(prev instanceof Table) || prev.len() != list.len() ? list : prev
})

let unseenResearchedUnits = Computed(function() {
  let res = {}
  let { unitTreeNodes = {}, unitResearchExp = {} } = campConfigs.get()
  let { unitsResearch = {} } = servProfile.get()
  let blueprints = availableBlueprints.get()
  let bCounts = blueprintCounts.get()
  let seenUnits = seenResearchedUnits.get()

  foreach(unitName, node in unitTreeNodes) {
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
      v[u] <- true
      sBlk[u] = true
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
register_command(function() {
  needDebugLines.set(!needDebugLines.get())
  console_print(needDebugLines.get() ? "Show lines over units" : "Show lines under units (as for all players)") 
}, "debug.tree_lines_over_units")

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
  remapNodesPositionsShiftX

  needDebugLines
}
