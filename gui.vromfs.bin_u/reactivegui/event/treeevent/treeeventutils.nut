from "%globalsDarg/darg_library.nut" import *
from "dagor.fs" import file_exists, read_text_from_file
from "json" import parse_json
from "%appGlobals/config/mapPointsPresentation.nut" import getTreeNodeView


const SAVED_PRESETS_PATH = "%appGlobals/config/eventMapPages"
const FILE_EXT = ".json"

let defaultMapSize = [600, 500]
const defaultGridSize = 100
const defaultPointSize = 50
const defaultMapBg = ""

const lineSectionLen = 6
const lineOutlineWidth = hdpxi(1)
const mapLineWidth = hdpx(7) + 2 * lineOutlineWidth

const LINE_DASHED = "dashed"
const LINE_SOLID = "solid"
let lineTypes = [LINE_DASHED, LINE_SOLID]

const VIEW_START = "start"
const VIEW_REWARD = "reward"
const VIEW_QUESTS = "quests"
const VIEW_NEXT_PAGE = "nextPage"
const VIEW_DEFAULT = "default"

function getPresetDataFromFile(path) {
  if (!path)
    return null
  local res = null
  try {
    let fileContent = read_text_from_file(path)
    res = parse_json(fileContent)
  }
  catch(e)
    logerr($"Failed to parse preset from file: {e}")

  return res
}

let loadPresetOnce = memoize(function(presetId) {
  let path = $"{SAVED_PRESETS_PATH}/{presetId}{FILE_EXT}"
  if (file_exists(path))
    return getPresetDataFromFile(path)
  logerr($"No file found for preset {presetId}!")
  return null
})

let mkEmptyPreset = @() {
  bg = defaultMapBg
  mapSize = defaultMapSize
  gridSize = defaultGridSize
  pointSize = defaultPointSize
  points = {}
  bgElements = []
  lines = []
}

let mkDefaultPoint = @(pos) { pos }
let mkDefaultLine = @(from, to) { from, to }

let findLineIdx = @(point1, point2, lines)
  lines.findindex(@(l)
    (l.from == point1 && l.to == point2)
    || (l.from == point2 && l.to == point1))

let getEventMapNodes = @(configs, id) id == null ? {} : (configs?.eventMapTree[id].nodes ?? {})

let isTimeInRange = @(timeRange, time) time >= (timeRange?.start ?? 0) && time <= (timeRange?.end ?? 0)

function resolveTreeEventId(configs, eventId, mainEventId, time) {
  let trees = configs?.eventMapTree
  if (trees == null)
    return null
  if (eventId in trees)
    return eventId
  if (eventId != mainEventId)
    return null

  local best = null
  local bestStart = -1
  foreach (id, tree in trees) {
    let tr = tree?.timeRange
    let start = tr?.start ?? 0
    if (isTimeInRange(tr ?? {}, time) && start > bestStart) {
      bestStart = start
      best = id
    }
  }
  return best
}

function nextTreeBoundary(trees, time) {
  local next = null
  foreach (_, tree in (trees ?? {})) {
    let tr = tree?.timeRange
    foreach (edge in [tr?.start, tr?.end != null ? tr.end + 1 : null])
      if (edge != null && edge > time && (next == null || edge < next))
        next = edge
  }
  return next
}

function updatePresetByTree(nodes, savedPreset = {}) {
  const columns = 5
  local rowOffset = 0

  local preset = {}
  let pages = {}
  let pageOrder = []

  let savedPoints = savedPreset?.points ?? {}

  function initPreset() {
    if (preset.len() == 0) {
      preset = mkEmptyPreset().__merge(preset, savedPreset)
      preset.points = clone preset.points
      preset.lines = clone preset.lines
    }
    return preset
  }

  foreach (nodeId in nodes.keys().sort()) {
    let page = nodes[nodeId]?.page ?? ""
    if (page not in pages) {
      pages[page] <- []
      pageOrder.append(page)
    }
    pages[page].append(nodeId)
  }
  pageOrder.sort()

  if (nodes.keys().findvalue(@(id) id not in savedPoints) != null) {
    let curPreset = initPreset()
    local totalRows = 0
    foreach (page in pageOrder)
      totalRows += (pages[page].len() + columns - 1) / columns + 1
    let neededH = curPreset.gridSize * (totalRows + 1)
    if (neededH > curPreset.mapSize[1])
      curPreset.mapSize = [curPreset.mapSize[0], neededH]
  }

  foreach (page in pageOrder) {
    let pageNodes = pages[page]
    local newIdx = 0
    foreach (nodeId in pageNodes)
      if (nodeId not in savedPoints) {
        let curPreset = initPreset()
        let { mapSize, gridSize } = curPreset
        let x = clamp(gridSize * (1 + newIdx % columns), 0, mapSize[0])
        let y = clamp(gridSize * (1 + rowOffset + newIdx / columns), 0, mapSize[1])
        curPreset.points[nodeId] <- mkDefaultPoint([x, y])
        newIdx += 1
      }
    rowOffset += (pageNodes.len() + columns - 1) / columns + 1
  }

  foreach (nodeId in nodes.keys().sort())
    foreach (req in (nodes[nodeId]?.reqNodes ?? [])) {
      if (req not in nodes || findLineIdx(nodeId, req, savedPreset?.lines ?? []) != null)
        continue
      let curPreset = initPreset()
      if (findLineIdx(nodeId, req, curPreset.lines) != null)
        continue
      curPreset.lines.append(mkDefaultLine(req, nodeId))
    }

  return {}.__merge(savedPreset, preset)
}

function getNodeViewType(node, nodes, ranks) {
  if (node?.isStart)
    return VIEW_START
  if ((node?.rewards ?? []).len() > 0 && node?.meta.quests == null)
    return VIEW_REWARD
  if (node?.meta.quests != null)
    return VIEW_QUESTS
  let myRank = ranks?[node?.page ?? ""] ?? 0
  foreach (req in (node?.reqNodes ?? []))
    if ((ranks?[nodes?[req].page ?? ""] ?? 0) > myRank)
      return VIEW_NEXT_PAGE
  return VIEW_DEFAULT
}

function getPageRanks(nodes) {
  let seen = {}
  foreach (_, node in nodes)
    seen[node?.page ?? ""] <- true
  let ranks = {}
  foreach (i, p in seen.keys().sort())
    ranks[p] <- i
  return ranks
}

function getTreeNodeViewTypes(nodes) {
  let ranks = getPageRanks(nodes)
  let res = {}
  foreach (id, node in nodes)
    res[id] <- getNodeViewType(node, nodes, ranks)
  return res
}

function getNodePageStarts(nodes) {
  let ranks = getPageRanks(nodes)
  let res = {}
  foreach (id, node in nodes) {
    let myRank = ranks?[node?.page ?? ""] ?? 0
    foreach (req in (node?.reqNodes ?? []))
      if ((ranks?[nodes?[req].page ?? ""] ?? 0) < myRank) {
        res[id] <- true
        break
      }
  }
  return res
}

function composeNodeViews(viewTypes, eventId = null) {
  let res = {}
  foreach (id, viewType in viewTypes)
    res[id] <- getTreeNodeView(eventId, viewType)
  return res
}

let getTreeNodeViews = @(nodes, eventId = null) composeNodeViews(getTreeNodeViewTypes(nodes), eventId)

return {
  loadPresetOnce
  updatePresetByTree
  findLineIdx
  mkDefaultLine
  getEventMapNodes
  resolveTreeEventId
  nextTreeBoundary
  getTreeNodeViews
  getTreeNodeViewTypes
  getNodePageStarts
  composeNodeViews
  lineSectionLen
  lineOutlineWidth
  mapLineWidth

  LINE_DASHED
  LINE_SOLID
  lineTypes

  VIEW_START
  VIEW_REWARD
  VIEW_QUESTS
  VIEW_NEXT_PAGE
  VIEW_DEFAULT
}
