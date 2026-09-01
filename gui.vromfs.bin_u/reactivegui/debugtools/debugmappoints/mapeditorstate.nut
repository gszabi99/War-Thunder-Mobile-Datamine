from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_settings_blk
from "console" import register_command
from "dagor.fs" import scan_folder, read_text_from_file, remove_file
from "dagor.time" import get_time_msec
from "dagor.workcycle" import setInterval, clearTimer
from "eventbus" import eventbus_send
from "io" import file
from "json" import object_to_json_string, parse_json
from "%sqstd/underscore.nut" import isEqual, deep_clone
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/config/mapPointsPresentation.nut" import getDefaultPointSize, defaultPointView
from "%rGui/event/treeEvent/treeEventUtils.nut" import updatePresetByTree, findLineIdx, mkDefaultLine,
  getEventMapNodes, getTreeNodeViews, lineSectionLen, LINE_DASHED
from "%rGui/event/treeEvent/segmentMath.nut" import getLineEndPoints
from "types" import Table, String, Array, Integer, Float


const SAVE_PATH = "../../skyquake/prog/scripts/wtm/globals/config/eventMapPages"
const SAVE_EXT = ".json"
const BG_ELEMS_COLLECTION = "../../skyquake/prog/scripts/wtm/globals/config/eventMapPages/_bg_elems_collection.json"
const MAX_HISTORY_LEN = 50
const AUTO_SAVE_INTERVAL = 5

const ELEM_POINT = "Point"
const ELEM_BG = "Bg Elem"
const ELEM_LINE = "Line"
const ELEM_MIDPOINT = "Midpoint"
const ELEM_LINE_END = "Line End"

const LINE_END_FROM = "from"
const LINE_END_TO = "to"
let lineEndPosField = { [LINE_END_FROM] = "fromPos", [LINE_END_TO] = "toPos" }

let scalableETypes = [ELEM_BG].reduce(@(res, v) res.$rawset(v, true), {})

let defaultMapSize = [2000, 1000]
const defaultGridSize = 200
const defaultLineWidth = 9
const defaultMapBg = ""

let isEventMapEditorOpened = mkWatched(persist, "isEventMapEditorOpened", false)
let isHeaderOptionsOpen = mkWatched(persist, "isHeaderOptionsOpen", true)
let isSidebarOptionsOpen = mkWatched(persist, "isSidebarOptionsOpen", true)

let needUseAutoSave = mkWatched(persist, "needUseAutoSave", false)

let loadedPageWithLastChange = mkWatched(persist, "loadedPageWithLastChange", null)
let savedPages = mkWatched(persist, "savedPages", {})
let bgCollection = mkWatched(persist, "bgCollection", {})
let historyMapElements = mkWatched(persist, "historyMapElements", [])

let selectedElem = mkWatched(persist, "selectedElem", null)
let currentPageId = mkWatched(persist, "currentPageId", null)
let curEventId = mkWatched(persist, "curEventId", null)
let availableEvents = Computed(@() (serverConfigs.get()?.eventMapTree ?? {}).keys().sort())
let curEventPages = Computed(@() savedPages.get().filter(@(p) p?.event == curEventId.get()))
let curEventNodeViews = Computed(@() getTreeNodeViews(getEventMapNodes(serverConfigs.get(), curEventId.get()), curEventId.get()))

let hasViewChanges = Watched(false) 
let transformInProgress = Watched(null)
let isShiftPressed = Watched(false)

let loadedPage = Computed(@() loadedPageWithLastChange.get()?.mes)
let tuningPoints = Computed(@() loadedPage.get()?.points ?? {})
let tuningBgElems = Computed(@() loadedPage.get()?.bgElements ?? [])
let pageLines = Computed(@() loadedPage.get()?.lines ?? [])
let pageBackground = Computed(@() loadedPage.get()?.bg ?? defaultMapBg)
let pageMapSize = Computed(@() loadedPage.get()?.mapSize ?? defaultMapSize)
let pageGridSize = Computed(@() loadedPage.get()?.gridSize ?? defaultGridSize)
let pageLineSectionLen = Computed(@() loadedPage.get()?.lineSectionLen ?? lineSectionLen)
let pageRoundedDashes = Computed(@() loadedPage.get()?.roundedDashes ?? true)
let pageLineType = Computed(@() loadedPage.get()?.lineType ?? LINE_DASHED)
let pageLineWidth = Computed(@() loadedPage.get()?.lineWidth ?? defaultLineWidth)
let pagePointSizes = Computed(@() loadedPage.get()?.pointSizes ?? {})
let curHistoryIdx = Computed(@() historyMapElements.get().findindex(@(h) h.mes == loadedPage.get()))

let selectedPointId = Computed(@()
  selectedElem.get()?.id not in tuningPoints.get() || selectedElem.get()?.eType != ELEM_POINT ? null
    : selectedElem.get().id)
let selectedBgElemIdx = Computed(@()
  selectedElem.get()?.eType != ELEM_BG || selectedElem.get()?.id not in tuningBgElems.get() ? null
    : selectedElem.get().id)
let selectedBgElem = Computed(@() tuningBgElems.get()?[selectedBgElemIdx.get()])
let selectedLineIdx = Computed(@()
  (selectedElem.get()?.eType == ELEM_LINE && selectedElem.get()?.id in pageLines.get())
      ? selectedElem.get().id
    : ((selectedElem.get()?.eType == ELEM_MIDPOINT || selectedElem.get()?.eType == ELEM_LINE_END)
        && selectedElem.get()?.subId in pageLines.get())
      ? selectedElem.get().subId
    : null)
let selectedLineMidpoints = Computed(@() pageLines.get()?[selectedLineIdx.get()].midpoints ?? [])
let selectedMidpointIdx = Computed(@()
  selectedElem.get()?.eType != ELEM_MIDPOINT || selectedElem.get()?.id  not in selectedLineMidpoints.get() ? null
    : selectedElem.get()?.id)

let selectedLineEnds = Computed(function() {
  let line = pageLines.get()?[selectedLineIdx.get()]
  if (line == null)
    return []
  let ends = getLineEndPoints(line, tuningPoints.get())
  let res = []
  foreach (endId in [LINE_END_FROM, LINE_END_TO]) {
    let pos = ends[endId]
    if (pos != null)
      res.append({ id = endId, pos })
  }
  return res
})
let selectedLineEndId = Computed(@() selectedElem.get()?.eType != ELEM_LINE_END
  ? null
  : selectedElem.get()?.id)

let curSavedPage = Computed(@() savedPages.get()?[currentPageId.get()])
let isCurPageChanged = Computed(@() loadedPage.get() != null
  && currentPageId.get() != null
  && !isEqual(loadedPage.get(), curSavedPage.get()))

let isEditAllowed = get_settings_blk()?.debug.useAddonVromSrc ?? false

let keyByElemId = {
  [ELEM_BG] = @(id) $"bg_elem_{id}",
  [ELEM_MIDPOINT] = @(id) $"midpoint_{id}",
  [ELEM_LINE_END] = @(id) $"line_end_{id}"
}
let getElemKey = @(id, eType) keyByElemId?[eType](id) ?? id

local lastHistoryIdx = curHistoryIdx.get()
loadedPageWithLastChange.subscribe(function(t) {
  if (t == null || curHistoryIdx.get() != null) {
    lastHistoryIdx = curHistoryIdx.get()
    return
  }
  local h = clone historyMapElements.get()
  let lastHistory = h?[h.len() - 1]
  let isStackToLast = lastHistory != null
    && lastHistory.id == t.id
    && lastHistory.timeEnd >= get_time_msec()

  if (isStackToLast)
    h[h.len() - 1] = t
  else {
    if (lastHistoryIdx != null && lastHistoryIdx < h.len())
      h = h.slice(0, lastHistoryIdx + 1)
    h.append(t)
    if (h.len() > MAX_HISTORY_LEN)
      h.remove(0)
  }
  lastHistoryIdx = curHistoryIdx.get()
  historyMapElements.set(h)
})

let mkEmptyPage = @() {
  bg = defaultMapBg
  mapSize = defaultMapSize
  gridSize = defaultGridSize
  lineSectionLen
  roundedDashes = true
  lineType = LINE_DASHED
  lineWidth = defaultLineWidth
  pointSizes = {}
  points = {}
  bgElements = []
  lines = []
}

let setMapElementsState = @(mes, id = "")
  loadedPageWithLastChange.set({ mes, id, timeEnd = get_time_msec() })

function changeCurPageField(key, value) {
  if (loadedPage.get() != null)
    setMapElementsState(loadedPage.get().__merge({ [key] = value }))
}

let clearPointsState = @() setMapElementsState(mkEmptyPage())

function loadPage(id, useCurrentId = false) {
  if (!useCurrentId)
    currentPageId.set(id)

  historyMapElements.set([])
  setMapElementsState(mkEmptyPage().__merge(savedPages.get()?[currentPageId.get()] ?? {}))
}
currentPageId.whiteListMutatorClosure(loadPage)

function selectEvent(eventId) {
  curEventId.set(eventId)
  let firstPage = savedPages.get().filter(@(p) p?.event == eventId).keys().sort()?[0]
  loadPage(firstPage)
}

function writePageToFile(id, page) {
  let pagefile = file($"{SAVE_PATH}/{id}{SAVE_EXT}", "wt+")
  pagefile.writestring(object_to_json_string(page, true))
  pagefile.close()
  dlog($"Saved to: wtm/globals/config/eventMapPages/{id}") 
}

function deleteFileByPageId(id) {
  let path = $"{SAVE_PATH}/{id}{SAVE_EXT}"
  let status = remove_file(path)
  if (status)
    dlog($"The file {id} has been deleted") 
  else
    logerr($"Error while trying to delete file: {path}")
}

function savePage(id, page) {
  hasViewChanges.set(true)
  savedPages.set(savedPages.get().__merge({ [id] = page }))
  writePageToFile(id, page)
}

function getPagesDataFromFiles(files) {
  let res = {}

  foreach(fileName in files) {
    if (!fileName.endswith(SAVE_EXT))
      continue
    let id = fileName.split("/").top().slice(0, -SAVE_EXT.len())
    if (id.startswith("_"))
      continue
    try {
      let fileContent = read_text_from_file(fileName)
      let page = parse_json(fileContent)
      if (page instanceof Table)
        res[id] <- page
    }
    catch(e)
      logerr($"Failed to parse page {fileName} from file: {e}")
  }

  return res
}

function selectAndLoadFirstPage() {
  let pages = savedPages.get()
  let cur = currentPageId.get()
  let id = (cur != null && cur in pages) ? cur : pages.findindex(@(_) true)
  loadPage(id)
}

let bgFieldErrors = {
  img = @(v) !(v instanceof String) ? "should be a string" : null
  size = @(v) !(v instanceof Array) || v.len() != 2 || null != v.findindex(@(c) !(c instanceof Integer))
    ? "should be an array of 2 integers"
    : null
  rotate = @(v) v != null && !(v instanceof Integer) && !(v instanceof Float) ? "should be numeric" : null
}

function reloadBgElemsCollection() {
  try {
    let fileContent = read_text_from_file(BG_ELEMS_COLLECTION)
    let collection = parse_json(fileContent)
    if (collection instanceof Table)
      bgCollection.set(collection.filter(function(e, id) {
        foreach (key, getErr in bgFieldErrors) {
          let err = getErr(e?[key])
          if (err != null) {
            logerr($"Load collection bg elem {id} field error: {key}: {err}")
            return false
          }
        }
        foreach (key, _ in e)
          if (key not in bgFieldErrors)
            logerr($"Unknown collection bg elem {id} field: {key}")
        return true
      }))
  }
  catch(e)
    logerr($"Failed to parse collection {BG_ELEMS_COLLECTION} from file: {e}")
}

isEventMapEditorOpened.subscribe(function(v) {
  if (v) {
    let pageFiles = scan_folder({ root = SAVE_PATH, vromfs = true, realfs = true, recursive = false })

    savedPages.set(getPagesDataFromFiles(pageFiles))

    let events = availableEvents.get()
    let ev = (curEventId.get() != null && events.contains(curEventId.get())) ? curEventId.get() : events?[0]
    if (ev != null)
      selectEvent(ev)
    else
      selectAndLoadFirstPage()

    reloadBgElemsCollection()
  } else if (hasViewChanges.get())
    eventbus_send("reloadDargVM", { msg = "debug event map points apply" })
})

function addOrEditPage(id, bg, mapSize) {
  loadPage(id)
  let event = loadedPage.get()?.event ?? curEventId.get()
  setMapElementsState(loadedPage.get().__merge({ bg, mapSize, gridSize = mapSize[0] / 10, event }))
}

function deletePage(id) {
  hasViewChanges.set(true)

  let pages = clone savedPages.get()
  pages.$rawdelete(id)
  savedPages.set(pages)
  deleteFileByPageId(id)

  let newCurrenPage = savedPages.get().findvalue(@(_) true) ?? {}

  loadPage(newCurrenPage?.id)
}

let selectElem = @(id, eType = ELEM_POINT, subId = null) selectedElem.set(id == null ? null : { id, eType, subId })
let deselectElem = @() selectedElem.set(null)
selectedElem.whiteListMutatorClosure(selectElem)
selectedElem.whiteListMutatorClosure(deselectElem)

function getMiddleScreenMapPos(size) {
  let aabb = gui_scene.getCompAABBbyKey("mapEditorMap")
  if (aabb == null)
    return [0, 0]
  let mapSize = pageMapSize.get()
  let { t, l, r } = aabb
  let posPx = [sw(50) - l, sh(50) - t]
  let scale = mapSize[0].tofloat() / max(1, r - l)
  return posPx.map(@(v, i) (v * scale + 0.5).tointeger() - size[i] / 2)
}

function editBgElement(idx, id, img, size, rotate) {
  if (loadedPage.get() == null)
    return

  let updatedElems = clone loadedPage.get().bgElements
  if (idx not in updatedElems)
    return
  updatedElems[idx] = updatedElems[idx].__merge({ id, img, size, rotate })
  changeCurPageField("bgElements", updatedElems)
}

function addBgElement(id, img, size, rotate) {
  if (loadedPage.get() == null)
    return null

  let updatedElems = clone loadedPage.get().bgElements
  updatedElems.append({ id, pos = getMiddleScreenMapPos(size), img, size, rotate })
  changeCurPageField("bgElements", updatedElems)
  return updatedElems.len() - 1
}

function pointViewSize(id, view, nodeViews, sizes) {
  let effView = (view ?? "") != "" ? view : (nodeViews?[id] ?? defaultPointView)
  return sizes?[effView] ?? getDefaultPointSize(effView)
}

function addOrEditPoint(id, view) {
  if (loadedPage.get() == null)
    clearPointsState()

  let mes = loadedPage.get()
  let updatedPoints = clone mes.points

  if (id in updatedPoints)
    updatedPoints[id] = updatedPoints[id].__merge({ view })
  else {
    let size = pointViewSize(id, view, curEventNodeViews.get(), pagePointSizes.get())
    updatedPoints[id] <- { pos = getMiddleScreenMapPos([size, size]), view }
  }

  setMapElementsState(mes.__merge({ points = updatedPoints }), id)
}

function deleteElement(id, eType, subId) {
  deselectElem()

  if (eType == ELEM_BG) {
    if (id not in tuningBgElems.get())
      return
    let bgElements = clone loadedPage.get().bgElements
    bgElements.remove(id)
    changeCurPageField("bgElements", bgElements)
    return
  }

  if (eType == ELEM_POINT) {
    if (id not in tuningPoints.get())
      return
    let points = clone loadedPage.get().points
    points.$rawdelete(id)
    changeCurPageField("points", points)
    return
  }

  if (eType == ELEM_LINE) {
    if (id not in pageLines.get())
      return
    let lines = clone loadedPage.get().lines
    lines.remove(id)
    changeCurPageField("lines", lines)
    return
  }

  if (eType == ELEM_MIDPOINT) {
    if (id not in pageLines.get()?[subId].midpoints)
      return
    let lines = clone loadedPage.get().lines
    let midpoints = clone lines[subId].midpoints
    let { from, to } = lines[subId]
    let count = midpoints.len() + (from in tuningPoints.get() ? 1 : 0) + (to in tuningPoints.get() ? 1 : 0)
    if (count < 3) {
      openFMsgBox({ text = "Unable to remove point when only 2 points left in the line" })
      selectElem(id, eType, subId)
      return
    }

    midpoints.remove(id)
    lines[subId] = lines[subId].__merge({ midpoints })
    changeCurPageField("lines", lines)
    selectElem(subId, ELEM_LINE) 
    return
  }

  if (eType == ELEM_LINE_END) {
    if (subId not in pageLines.get())
      return
    let field = lineEndPosField[id]
    let lines = clone loadedPage.get().lines
    let line = clone lines[subId]
    if (field in line)
      line.$rawdelete(field)
    lines[subId] = line
    changeCurPageField("lines", lines)
    selectElem(subId, ELEM_LINE) 
    return
  }
}

function copyElement(id, eType) {
  if (eType == ELEM_BG) {
    let elem = deep_clone(tuningBgElems.get()?[id])
    if (elem == null)
      return
    let bgElements = clone tuningBgElems.get()
    elem.pos = elem.pos.map(@(v) v + 20)
    bgElements.append(elem)
    changeCurPageField("bgElements", bgElements)
    selectElem(bgElements.len() - 1, eType)
    return
  }
}

function setByHistory(historyIdx) {
  let h = historyMapElements.get()?[historyIdx]
  if (h != null)
    loadedPageWithLastChange.set(h)
}

function saveCurrentPage() {
  if (currentPageId.get() != null && loadedPage.get() != null)
    savePage(currentPageId.get(), loadedPage.get())
}

let delayedAutoSave = @() isCurPageChanged.get() ? saveCurrentPage() : null
needUseAutoSave.subscribe(@(v) v ? setInterval(AUTO_SAVE_INTERVAL, delayedAutoSave) : clearTimer(delayedAutoSave))

function applyTransformProgress() {
  if (loadedPage.get() == null || transformInProgress.get() == null)
    return

  let { id = null, eType = null, subId = null } = selectedElem.get()
  let { pos, mapSizePx, size = null, flip = null } = transformInProgress.get()
  transformInProgress.set(null)
  let { mapSize } = loadedPage.get()
  let posExt = pos.map(@(v, i) (v.tofloat() * mapSize[i] / mapSizePx[i] + 0.5).tointeger())
  let sizeExt = size == null ? null
    : size.map(@(v, i) (v.tofloat() * mapSize[i] / mapSizePx[i] + 0.5).tointeger())

  if (eType == ELEM_BG) {
    let bgElements = clone loadedPage.get().bgElements
    if (id in bgElements) {
      let { flipX = false, flipY = false } = bgElements[id]
      bgElements[id] = bgElements[id].__merge({
        pos = posExt
        size = sizeExt ?? bgElements[id].size
        flipX = flip?[0] ? !flipX : flipX
        flipY = flip?[1] ? !flipY : flipY
      })
      foreach (f in ["flipX", "flipY"])
        if (!bgElements[id][f])
          bgElements[id].$rawdelete(f)

      changeCurPageField("bgElements", bgElements)
    }
    return
  }

  if (eType == ELEM_POINT) {
    let points = clone loadedPage.get().points
    if (id not in points)
      return
    let viewSize = pointViewSize(id, points[id]?.view, curEventNodeViews.get(), pagePointSizes.get())
    let oldPos = points[id].pos
    let newPos = posExt.map(@(v) (v + viewSize / 2).tointeger())
    points[id] = points[id].__merge({ pos = newPos })

    let dx = newPos[0] - oldPos[0]
    let dy = newPos[1] - oldPos[1]
    let lines = clone loadedPage.get().lines
    foreach (i, line in lines) {
      local upd = null
      if (line.from == id && line?.fromPos != null)
        upd = { fromPos = [line.fromPos[0] + dx, line.fromPos[1] + dy] }
      if (line.to == id && line?.toPos != null)
        upd = (upd ?? {}).__merge({ toPos = [line.toPos[0] + dx, line.toPos[1] + dy] })
      if (upd != null)
        lines[i] = line.__merge(upd)
    }
    setMapElementsState(loadedPage.get().__merge({ points, lines }))
    return
  }

  if (eType == ELEM_MIDPOINT) {
    if (id not in pageLines.get()?[subId].midpoints)
      return
    let lines = clone loadedPage.get().lines
    let midpoints = clone lines[subId].midpoints 
    midpoints[id] = posExt
    lines[subId] = lines[subId].__merge({ midpoints }) 
    changeCurPageField("lines", lines)
    return
  }

  if (eType == ELEM_LINE_END) {
    if (subId not in pageLines.get())
      return
    let lines = clone loadedPage.get().lines
    lines[subId] = lines[subId].__merge({ [lineEndPosField[id]] = posExt }) 
    changeCurPageField("lines", lines)
    return
  }
}

function makePageFiles(pages) {
  foreach (id, page in pages) {
    let pagefile = file($"{SAVE_PATH}/{id}{SAVE_EXT}", "wt+")
    pagefile.writestring(object_to_json_string(page, true))
    pagefile.close()
  }
}

function addLine(from, to) {
  let idx = findLineIdx(from, to, pageLines.get())
  if (idx != null)
    return "Line already exists"

  let line = mkDefaultLine(from, to)
  foreach(id in [from, to])
    if (id not in tuningPoints.get()) {
      let { pos = null, size = null } = tuningBgElems.get().findvalue(@(e) e.id == id)
      if (pos == null || size == null)
        return $"bg elem {id} not found"
      line.midpoints <- (line?.midpoints ?? []).append(pos.map(@(v, a) v + size[a] / 2))
    }

  let lines = clone pageLines.get()
  lines.append(line)
  changeCurPageField("lines", lines)
  selectElem(lines.len() - 1, ELEM_LINE)
  return ""
}

function changeLine(idx, line) {
  if (idx not in pageLines.get())
    return

  let lines = clone pageLines.get()
  lines[idx] = line
  changeCurPageField("lines", lines)
}


function createPageByTree(eventId) {
  let tree = serverConfigs.get()?.eventMapTree[eventId]
  if (tree == null)
    return

  let nodesByPage = {}
  foreach (nodeId, node in tree?.nodes ?? {}) {
    let page = node?.page ?? ""
    if (page not in nodesByPage)
      nodesByPage[page] <- {}
    nodesByPage[page][nodeId] <- node
  }

  let pages = {}
  foreach (page, pageNodes in nodesByPage) {
    let pageId = $"{eventId}_{page}"
    pages[pageId] <- updatePresetByTree(pageNodes, savedPages.get()?[pageId] ?? {})
      .__merge({ event = eventId })
  }

  savedPages.set(savedPages.get().__merge(pages))
  makePageFiles(pages)
  selectEvent(eventId)
}

register_command(@() isEventMapEditorOpened.set(true), "ui.debug.event_map_editor")

return {
  isEventMapEditorOpened
  isHeaderOptionsOpen
  isSidebarOptionsOpen
  isCurPageChanged
  isEditAllowed

  currentPageId
  curEventId
  availableEvents
  curEventPages
  curEventNodeViews
  selectEvent
  savedPages
  addOrEditPage
  loadPage
  deletePage

  transformInProgress
  isShiftPressed
  applyTransformProgress
  saveCurrentPage

  loadedPage
  changeCurPageField

  selectedPointId
  addOrEditPoint
  tuningPoints
  pageLines
  addLine
  changeLine

  historyMapElements
  setByHistory
  curHistoryIdx

  pageMapSize
  pageGridSize
  pageLineSectionLen
  pageRoundedDashes
  pageLineType
  pageLineWidth
  pageBackground
  pagePointSizes
  pointViewSize

  selectedElem
  selectedLineIdx
  selectedLineMidpoints
  selectedMidpointIdx
  selectedLineEnds
  selectedLineEndId
  selectElem
  deselectElem
  deleteElement
  copyElement

  selectedBgElemIdx
  selectedBgElem
  addBgElement
  editBgElement
  tuningBgElems
  bgCollection

  needUseAutoSave
  createPageByTree
  closeEventMapEditor = @() isEventMapEditorOpened.set(false)

  ELEM_POINT
  ELEM_BG
  ELEM_LINE
  ELEM_MIDPOINT
  ELEM_LINE_END
  scalableETypes
  getElemKey
}
