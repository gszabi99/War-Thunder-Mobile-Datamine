from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/pServerApi.nut" import eventMapNodeInProgress
from "%appGlobals/userstats/serverTime.nut" import serverTime, isServerTimeValid
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%rGui/event/eventState.nut" import curEvent, MAIN_EVENT_ID
from "%rGui/event/treeEvent/treeEventUtils.nut" import loadPresetOnce, updatePresetByTree, getEventMapNodes,
  resolveTreeEventId, nextTreeBoundary, getTreeNodeViewTypes, getNodePageStarts, composeNodeViews, lineSectionLen,
  mapLineWidth, LINE_DASHED
from "%rGui/unlocks/unlocks.nut" import activeUnlocks


let defaultMapSize = [2000, 1000]
const defaultGridSize = 200


const NS_UNLOCKED = 0x1 
const NS_PURCHASED = 0x2
const NS_REWARDS_RECEIVED = 0x4

const NODE_QUESTS = "quests"
const NODE_REWARD = "reward"
const NODE_INTERMEDIATE = "intermediate"

const NODE_LOCKED = "locked"
const NODE_AVAILABLE = "available"
const NODE_PURCHASED = "purchased"
const NODE_RECEIVED = "received"

let selectedPointId = mkWatched(persist, "selectedPointId", null)
let curPage = mkWatched(persist, "treeEventCurPage", null)

let openedTreeEventId = Watched(null)
let treeBoundary = Watched({ time = 0 })

function updateOpenedTree() {
  if (!isServerTimeValid.get()) {
    openedTreeEventId.set(null)
    treeBoundary.set({ time = 0 })
    return
  }
  let configs = serverConfigs.get()
  let time = serverTime.get()
  openedTreeEventId.set(resolveTreeEventId(configs, curEvent.get(), MAIN_EVENT_ID, time))
  treeBoundary.set({ time = nextTreeBoundary(configs?.eventMapTree, time) ?? 0 })
}

let onTreeBoundary = @() updateOpenedTree()

treeBoundary.subscribe(@(v) v.time == 0 ? clearExtTimer(onTreeBoundary)
  : resetExtTimeout(v.time - serverTime.get(), onTreeBoundary))

updateOpenedTree()
foreach (w in [serverConfigs, curEvent, isServerTimeValid])
  w.subscribe(@(_) updateOpenedTree())

let curEventMapNodes = Computed(@() getEventMapNodes(serverConfigs.get(), openedTreeEventId.get()))
let hasTreeMap = @(id) resolveTreeEventId(serverConfigs.get(), id, MAIN_EVENT_ID, serverTime.get()) != null
let curEventMapStatus = Computed(@() servProfile.get()?.eventMapStatus[openedTreeEventId.get()] ?? {})

let curEventMapCurrencies = Computed(function() {
  let res = []
  foreach (_, node in curEventMapNodes.get()) {
    let currencyId = node?.currencyId
    if ((node?.price ?? 0) > 0 && currencyId != null && currencyId != "" && !res.contains(currencyId))
      res.append(currencyId)
  }
  return res
})

let curEventClusters = Computed(function() {
  let res = {}
  foreach (_, node in curEventMapNodes.get())
    if (node?.meta.quests != null)
      res[node.meta.quests] <- true
  return res
})
let curEventUnlocks = keepref(Computed(@() activeUnlocks.get().filter(@(u) (u?.meta.quests ?? "") in curEventClusters.get())))

function getEventNodeType(node) {
  if (node?.meta.quests != null)
    return NODE_QUESTS
  if ((node?.rewards ?? []).len() > 0)
    return NODE_REWARD
  return NODE_INTERMEDIATE
}

let nodeViewTypes = Computed(@() getTreeNodeViewTypes(curEventMapNodes.get()))
let nodeViews = Computed(@() composeNodeViews(nodeViewTypes.get(), openedTreeEventId.get()))
let pageStartNodes = Computed(@() getNodePageStarts(curEventMapNodes.get()))

let isUnlocked = @(status) ((status ?? 0) & NS_UNLOCKED) != 0
let isPurchased = @(status) ((status ?? 0) & NS_PURCHASED) != 0
let isRewardsReceived = @(status) ((status ?? 0) & NS_REWARDS_RECEIVED) != 0

let getNodeStatusKind = @(status)
  isRewardsReceived(status) ? NODE_RECEIVED
    : isPurchased(status) ? NODE_PURCHASED
    : isUnlocked(status) ? NODE_AVAILABLE
    : NODE_LOCKED

let nodeStatusKind = Computed(function() {
  let status = curEventMapStatus.get()
  let res = {}
  foreach (id, _ in curEventMapNodes.get())
    res[id] <- getNodeStatusKind(status?[id])
  return res
})

let pagesList = Computed(function() {
  let seen = {}
  let res = []
  foreach (_, node in curEventMapNodes.get()) {
    let page = node?.page ?? ""
    if (page not in seen) {
      seen[page] <- true
      res.append(page)
    }
  }
  res.sort()
  return res
})

let curPageResolved = Computed(function() {
  let pages = pagesList.get()
  let p = curPage.get()
  return (p != null && pages.contains(p)) ? p : pages?[0]
})

let curPageNodes = Computed(@() curEventMapNodes.get().filter(@(node) (node?.page ?? "") == curPageResolved.get()))

let currentPageState = Computed(function() {
  let eventId = openedTreeEventId.get()
  let page = curPageResolved.get()
  if (eventId == null || page == null)
    return null
  return updatePresetByTree(curPageNodes.get(), loadPresetOnce($"{eventId}_{page}") ?? {})
})

let curPageBgElems = Computed(@() currentPageState.get()?.bgElements ?? [])
let curPageBackground = Computed(@() currentPageState.get()?.bg ?? "")
let curPageMapSize = Computed(@() currentPageState.get()?.mapSize ?? defaultMapSize)
let curPageGridSize = Computed(@() currentPageState.get()?.gridSize ?? defaultGridSize)
let curPagePoints = Computed(@() currentPageState.get()?.points ?? {})
let curPageLines = Computed(@() currentPageState.get()?.lines ?? [])
let curPageLineSectionLen = Computed(@() currentPageState.get()?.lineSectionLen ?? lineSectionLen)
let curPageRoundedDashes = Computed(@() currentPageState.get()?.roundedDashes ?? true)
let curPageLineType = Computed(@() currentPageState.get()?.lineType ?? LINE_DASHED)
let curPageLineWidth = Computed(function() {
  let w = currentPageState.get()?.lineWidth
  return w != null ? hdpx(w) : mapLineWidth
})
let curPagePointSizes = Computed(@() currentPageState.get()?.pointSizes ?? {})

let getClusterQuests = @(clusterId) curEventUnlocks.get().filter(@(u) u?.meta.quests == clusterId)

openedTreeEventId.subscribe(function(_) {
  selectedPointId.set(null)
  curPage.set(null)
})

curPage.subscribe(@(_) selectedPointId.set(null))

return {
  openedTreeEventId
  hasTreeMap
  curPageBgElems
  curPageBackground
  curPageMapSize
  curPageGridSize
  selectedPointId
  curEventUnlocks

  curEventMapNodes
  curEventMapCurrencies
  curEventMapStatus
  getEventNodeType
  isUnlocked
  isPurchased
  isRewardsReceived
  nodeViews
  nodeViewTypes
  pageStartNodes
  nodeStatusKind
  NODE_QUESTS
  NODE_REWARD
  NODE_INTERMEDIATE
  NODE_LOCKED
  NODE_AVAILABLE
  NODE_PURCHASED
  NODE_RECEIVED

  pagesList
  curPage
  curPageResolved
  curPagePoints
  curPageLines
  curPageLineSectionLen
  curPageRoundedDashes
  curPageLineType
  curPageLineWidth
  curPagePointSizes

  getClusterQuests

  eventMapNodeInProgress
}
